defmodule Discovery.Mixfile do
  use Mix.Project

  def project do
    [app: :discovery,
     version: "0.0.1",
     elixir: "~> 0.13.3",
     config_path: "config/#{Mix.env}.exs",
     deps: deps]
  end

  def application do
    [
      mod: {Discovery, []},
      applications: [:consul],
      registered: [:node_connector],
      env: [
        retry_connect_ms: 5000
      ]
    ]
  end

  defp deps do
    [
      {:consul, git: "git@github.com:undeadlabs/consul-ex.git"}
    ]
  end
end
