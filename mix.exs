defmodule NervesHub.MixProject do
  use Mix.Project

  Application.put_env(
    :nerves_hub_link_http,
    :nerves_provisioning,
    Path.expand("priv/provisioning.conf")
  )

  def project do
    [
      app: :nerves_hub_link_http,
      version: "0.8.2",
      description: description(),
      dialyzer: dialyzer(),
      docs: [main: "readme", extras: ["README.md"]],
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      deps: deps()
    ]
  end

  def application do
    [
      env: [
        device_api_host: "device.nerves-hub.org",
        device_api_port: 443,
        device_api_sni: "device.nerves-hub.org",
        fwup_public_keys: []
      ],
      extra_applications: [:logger, :iex],
      mod: {NervesHubLinkHTTP.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]

  defp elixirc_paths(_), do: ["lib"]

  defp description do
    "The NervesHub HTTP client connection"
  end

  defp dialyzer do
    [
      plt_add_apps: [:inets]
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/nerves-hub/nerves_hub_link_http"}
    ]
  end

  defp deps do
    [
      {:fwup, "~> 0.4.0"},
      {:hackney, "~> 1.10"},
      {:jason, "~> 1.0"},
      {:nerves_hub_cli, "~> 0.9", runtime: false},
      {:nerves_runtime, "~> 0.8"},
      {:x509, "~> 0.5"},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.18", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:mox, "~> 1.0", only: :test}
    ]
  end
end
