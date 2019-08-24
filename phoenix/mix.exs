defmodule LoginProxy.Mixfile do
  use Mix.Project

  def project do
    [app: :login_proxy,
     version: "0.0.2",
     elixir: "~> 1.5",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     test_coverage: [tool: ExCoveralls],
     deps: deps()]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {LoginProxy, []},
     applications: [:dynamic_config, :phoenix, :phoenix_pubsub, :phoenix_html, :cowboy,
      :logger, :gettext, :esaml, :redix, :httpotion, :uuid, :xml_builder,
      ]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix, "~> 1.4.0"},
     {:phoenix_pubsub, "~> 1.1"},
     {:phoenix_html, "~> 2.11"},
     {:phoenix_live_reload, "~> 1.2", only: :dev},
     {:ecto_sql, "~> 3.0"},
     {:phoenix_ecto, "~> 4.0"},
     {:gettext, "~> 0.11"},
     {:elixir_uuid, "~> 1.2"},
     {:esaml, github: "sudrao/esaml", tag: "v1.2"},
     {:redix, ">= 0.0.0"},
     {:httpotion, "~> 3.0.2"},
     {:xml_builder, "~> 0.0.6"},
     {:joken, "~> 2.0"},
     {:junit_formatter, "~> 1.3", only: [:test]},
     {:excoveralls, "~> 0.6", only: :test},
     {:dynamic_config, github: "rhetzler/dynamic_config", ref: '9a05a99ced627c764b54aa5241af2d92f1ddcaba' },
     {:poison, "~> 3.1"},
     {:jason, "~> 1.0"},
     {:cowboy, "~> 2.5", override: true},
     {:plug_cowboy, "~> 2.0"},
     {:distillery, "~> 1.5.2"},
     {:plug, "~> 1.7"},
     ]
  end
end
