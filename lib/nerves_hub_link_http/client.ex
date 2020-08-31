defmodule NervesHubLinkHTTP.Client do
  @moduledoc """
  A behaviour module for customizing the tool used for HTTP requests to NervesHub.

  Also allows handling FWUP messages and errors

  By default, `:hackney` is used for completing HTTP requests and all FWUP messages
  are logged to STDOUT. To specify your own module to use, update your `config.exs`

  ```elixir
  config :nerves_hub_link_http, client: MyApp.NervesHubLinkHTTP.Client
  ```
  """

  alias NervesHubLinkHTTP.{Certificate, Client.Default}

  @typedoc "Firmware update progress, completion or error report"
  @type fwup_message ::
          {:ok, non_neg_integer(), String.t()}
          | {:warning, non_neg_integer(), String.t()}
          | {:error, non_neg_integer(), String.t()}
          | {:progress, 0..100}

  @type method :: :get | :put | :post
  @type url :: binary()
  @type header :: {binary(), binary()}
  @type body :: binary()
  @type opts :: keyword()
  @type response :: {:ok, map()} | {:error, any()}

  @doc """
  Called on firmware update reports.

  The return value of this function is not checked.
  """
  @callback handle_fwup_message(fwup_message()) :: :ok

  @doc """
  Called when downloading a firmware update fails.

  The return value of this function is not checked.
  """
  @callback handle_error(any()) :: :ok

  @doc """
  Performs the HTTP request
  """
  @callback request(method(), url(), [header()], body(), opts()) :: response()

  @cert "nerves_hub_cert"
  @key "nerves_hub_key"

  @spec me() :: response()
  def me(), do: request(:get, "/device/me", [])

  @doc """
  This function is called internally by NervesHubLinkHTTP to notify clients of fwup progress.
  """
  @spec handle_fwup_message(fwup_message()) :: :ok
  def handle_fwup_message(data) do
    _ = apply_wrap(client(), :handle_fwup_message, [data])
    :ok
  end

  @doc """
  This function is called internally by NervesHubLinkHTTP to notify clients of fwup errors.
  """
  @spec handle_error(any()) :: :ok
  def handle_error(data) do
    _ = apply_wrap(client(), :handle_error, [data])
  end

  @spec update(Keyword.t()) :: response()
  def update(opts \\ []), do: request(:get, "/device/update", [], opts)

  @spec request(method(), binary(), map() | binary() | list(), Keyword.t()) :: response()
  def request(method, path, params, opts \\ [])

  def request(:get, path, params, opts) when is_map(params) do
    url = url(path) <> "?" <> URI.encode_query(params)

    client().request(:get, url, headers(), [], request_opts(opts))
    |> check_response()
  end

  def request(verb, path, params, opts) when is_map(params) do
    with {:ok, body} <- Jason.encode(params) do
      request(verb, path, body, opts)
    end
  end

  def request(verb, path, body, opts) do
    client().request(verb, url(path), headers(), body, request_opts(opts))
    |> check_response()
  end

  @spec url(binary()) :: url()
  def url(path), do: endpoint() <> path

  # Catches exceptions and exits
  defp apply_wrap(client, function, args) do
    apply(client, function, args)
  catch
    :error, reason -> {:error, reason}
    :exit, reason -> {:exit, reason}
    err -> err
  end

  defp client(), do: Application.get_env(:nerves_hub_link_http, :client, Default)

  defp check_response(response) do
    case response do
      {:ok, _} ->
        NervesHubLinkHTTP.Connection.connected()

      {:error, _} ->
        NervesHubLinkHTTP.Connection.disconnected()

      _ ->
        raise(
          "invalid HTTP response. request/5 must return a tuple with {:ok, resp} or {:error, resp}"
        )
    end

    response
  end

  defp endpoint do
    host = Application.get_env(:nerves_hub_link_http, :device_api_host)
    port = Application.get_env(:nerves_hub_link_http, :device_api_port)
    "https://#{host}:#{port}"
  end

  defp headers do
    headers = [{"X-NervesHub-fwup-version", fwup_version()}, {"Content-Type", "application/json"}]

    Nerves.Runtime.KV.get_all_active()
    |> Enum.reduce(headers, fn
      {"nerves_fw_" <> key, value}, headers ->
        [{"X-NervesHub-" <> key, value} | headers]

      _, headers ->
        headers
    end)
  end

  defp request_opts(opts) do
    ssl_opts = Keyword.merge(ssl_options(), Keyword.get(opts, :ssl_opts, []))

    [
      ssl_options: ssl_opts,
      recv_timeout: 60_000
    ]
  end

  defp ssl_options() do
    cert = Nerves.Runtime.KV.get(@cert) |> Certificate.pem_to_der()

    key =
      with key when not is_nil(key) <- Nerves.Runtime.KV.get(@key) do
        case X509.PrivateKey.from_pem(key) do
          {:error, :not_found} -> <<>>
          {:ok, decoded} -> X509.PrivateKey.to_der(decoded)
        end
      else
        nil -> <<>>
      end

    sni = Application.get_env(:nerves_hub_link_http, :device_api_sni)

    [
      cacerts: Certificate.ca_certs(),
      cert: cert,
      key: {:ECPrivateKey, key},
      server_name_indication: to_charlist(sni)
    ]
  end

  defp fwup_version do
    {version_string, 0} = System.cmd("fwup", ["--version"])
    String.trim(version_string)
  end
end
