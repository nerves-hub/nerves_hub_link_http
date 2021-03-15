defmodule NervesHubLinkHTTP do
  @moduledoc """
  Official client to use HTTP polling for firmware updates from NervesHub
  """

  require Logger

  alias NervesHubLinkHTTP.{Client, HTTPFwupStream}

  @doc """
  Check for an available update.

  The update is not automatically applied.
  """
  @spec update?(Keyword.t()) :: {:ok, String.t()} | {:ok, :no_update} | {:error, any()}
  def update?(opts \\ []) do
    case Client.update(opts) do
      {:ok, %{"data" => %{"update_available" => true, "firmware_url" => url}}} -> {:ok, url}
      {:ok, %{"data" => %{"update_available" => false}}} -> {:ok, :no_update}
      {:error, _} = err -> err
    end
  end

  @doc """
  Apply the update at the provided `url`.
  """
  @spec apply_update(String.t()) :: no_return()
  def apply_update(url) when is_binary(url) do
    Logger.info("[NervesHubLinkHTTP] Downloading firmware: #{url}")
    {:ok, http} = HTTPFwupStream.start_link(self())
    # Spawn to allow async messages from FWUP.
    _ = spawn_monitor(HTTPFwupStream, :get, [http, url])
    update_receive()
  end

  @doc """
  Check for an available update and automatically apply it.
  """
  @spec update(Keyword.t()) :: no_return() | :no_update | {:error, any()}
  def update(opts \\ []) do
    case update?(opts) do
      {:ok, :no_update} -> :no_update
      {:ok, url} when is_binary(url) -> apply_update(url)
      {:error, _} = err -> err
    end
  end

  defp update_receive() do
    receive do
      # Reboot when FWUP is done applying the update.
      {:fwup, {:ok, 0, message}} ->
        Logger.info("[NervesHubLinkHTTP] Firmware download complete")
        _ = Client.handle_fwup_message({:ok, 0, message})
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
