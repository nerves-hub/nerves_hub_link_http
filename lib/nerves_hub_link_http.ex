defmodule NervesHubLinkHTTP do
  require Logger

  alias NervesHubLinkHTTP.{Client, HTTPFwupStream}

  def update do
    case Client.update() do
      {:ok, %{"data" => %{"update_available" => true, "firmware_url" => url}}} ->
        Logger.info("[NervesHubLinkHTTP] Downloading firmware: #{url}")
        {:ok, http} = HTTPFwupStream.start_link(self())
        # Spawn to allow async messages from FWUP.
        spawn_monitor(HTTPFwupStream, :get, [http, url])
        update_receive()

      {:ok, %{"data" => %{"update_available" => false}}} ->
        :no_update

      {:error, _} = err ->
        err
    end
  end

  def update_receive() do
    receive do
      # Reboot when FWUP is done applying the update.
      {:fwup, {:ok, 0, message}} ->
        Logger.info("[NervesHubLinkHTTP] Firmware download complete")
        _ = Client.handle_fwup_message(message)
        Nerves.Runtime.reboot()

      # Allow client to handle other FWUP message.
      {:fwup, msg} ->
        _ = Client.handle_fwup_message(msg)
        update_receive()

      {:http_error, error} ->
        _ = Client.handle_error(error)
        {:error, {:http_error, error}}

      # If the HTTP stream finishes before fwup, just
      # Wait for FWUP to finish.
      {:DOWN, _, :process, _, :normal} ->
        update_receive()

      # If the HTTP stream fails with an error,
      # return
      {:DOWN, _, :process, _, error} ->
        _ = Client.handle_error(error)
        error
    end
  end
end
