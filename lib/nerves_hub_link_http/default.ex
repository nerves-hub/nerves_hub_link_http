defmodule NervesHubLinkHTTP.Client.Default do
  @moduledoc """
  Default NervesHubLinkHTTP.Client implementation

  Requests are completed via `:hackney`
  FWUP messages are simply logged as warnings

  See `NervesHugLinkHTTP.Client` for more details.
  """

  alias NervesHubLinkHTTP.Client

  require Logger

  @behaviour Client

  @impl Client
  def handle_fwup_message({:progress, percent}) when rem(percent, 25) == 0 do
    Logger.debug("[NervesHubLinkHTTP] FWUP PROG: #{percent}%")
  end

  def handle_fwup_message({:error, _, message}) do
    Logger.error("[NervesHubLinkHTTP] FWUP ERROR: #{message}")
  end

  def handle_fwup_message({:warning, _, message}) do
    Logger.warn("[NervesHubLinkHTTP] FWUP WARN: #{message}")
  end

  def handle_fwup_message(fwup_message) do
    Logger.warn("[NervesHubLinkHTTP] Unknown FWUP message: #{inspect(fwup_message)}")
  end

  @impl Client
  def handle_error(error) do
    Logger.warn("[NervesHubLinkHTTP] Firmware stream error: #{inspect(error)}")
  end

  @impl Client
  def request(method, url, headers, body, opts \\ []) do
    method
    |> :hackney.request(url, headers, body, opts)
    |> resp()
  end

  defp resp({:ok, status_code, _headers, client_ref})
       when status_code >= 200 and status_code < 300 do
    case :hackney.body(client_ref) do
      {:ok, ""} ->
        {:ok, ""}

      {:ok, body} ->
        Jason.decode(body)

      error ->
        error
    end
  after
    :hackney.close(client_ref)
  end

  defp resp({:ok, _status_code, _headers, client_ref}) do
    case :hackney.body(client_ref) do
      {:ok, ""} ->
        {:error, ""}

      {:ok, body} ->
        resp =
          case Jason.decode(body) do
            {:ok, body} -> body
            body -> body
          end

        {:error, resp}

      error ->
        error
    end
  after
    :hackney.close(client_ref)
  end

  defp resp(resp) do
    {:error, resp}
  end
end
