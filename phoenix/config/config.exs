# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :login_proxy, LoginProxy.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Rdg2H4RqfH6xKJW8DedHQ1lOJF4fYBMkj3HZ29DbE04KgRVJ6UeHASe7eL3Y+Gyx",
  render_errors: [view: LoginProxy.ErrorView, accepts: ~w(html json)],
  pubsub: [name: LoginProxy.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  handle_sasl_reports: true,
  metadata: [:request_id]

# esaml
config :login_proxy, :esaml,
  base: "http://some.kora.sapkora.com",
  key_file: Path.join([Mix.Project.build_path, "..", "..", "JAM_CLM_KEY.pem"]),
  cert_file: Path.join([Mix.Project.build_path, "..", "..", "JAM_CLM.pem"]),
  idp_metadata_url: "https://accounts400.sap.com/saml2/metadata/accounts.sap.com",
  allow_stale: false,
  esaml_util: :esaml_util

config :login_proxy, :redis,
  pool_size: 5,
  key_prefix: "LOGIN::PROXY::"

config :login_proxy, :redix, LoginProxy.Config.RedisDocker

config :login_proxy, :browser_server_url, {LoginProxy.Config.DownstreamDocker, "KORA_UI_PORT"}
config :login_proxy, :api_server_url, {LoginProxy.Config.DownstreamDocker, "KORA_APP_API_PORT"}

config :login_proxy, :http_request_module, HTTPotion

config :login_proxy, :jwt,
  hs256_secret: "g4AhQAENOGwB3zcAvg-nFDUhuPivAggFEMRcYLo8V5rrClX7UFJ5iX2yU1GEJI202HTS7_TBRTwWhgOTHnvwFA"

# This info could be provided by a service later on.
config :login_proxy, tenants: [
  %{
    hostname: "host1.com",
    name: "Tenant1",
    uuid: "50c5a290-146d-4d54-944c-1bfad270718d",
    service_provider_issuer: "issuer1"
  },
  %{
    hostname: "host2.com",
    name: "Tenant2",
    uuid: "c75ebed8-b329-4584-afc9-fbc9549e9646",
    service_provider_issuer: "issuer2"
  },
]
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
