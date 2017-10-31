# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :login_proxy, LoginProxy.Endpoint,
  url: [host: "localhost"],
  dynamic_config: LoginProxy.Config.EndpointDocker,
  render_errors: [view: LoginProxy.ErrorView, accepts: ~w(html json)],
  pubsub: [name: LoginProxy.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  handle_sasl_reports: true,
  metadata: [:request_id]

config :httpotion, :default_timeout, 30_000 # 30 seconds

# esaml
config :login_proxy, :esaml,
  key_file: Path.join([Mix.Project.build_path, "..", "..", "JAM_CLM_KEY.pem"]),
  cert_file: Path.join([Mix.Project.build_path, "..", "..", "JAM_CLM.pem"]),
  allow_stale: false,
  esaml_util: :esaml_util

config :login_proxy, :redis,
  pool_size: 5,
  key_prefix: "LOGIN::PROXY::"

config :login_proxy, :redix, LoginProxy.Config.RedisDocker

config :login_proxy, :browser_server_url, {LoginProxy.Config.DownstreamDocker, "KORA_UI_PORT"}
config :login_proxy, :api_server_url, {LoginProxy.Config.DownstreamDocker, "KORA_APP_API_PORT"}

config :login_proxy, :http_request_module, HTTPotion

config :login_proxy, :jwt_hs256_secret, {DynamicConfig.Env, "JWT_SECRET"}

config :login_proxy, idps: [
  %{
    server: "localhost:4050",
    base: "http://localhost:4050",
    idp_metadata_url: "https://dev-jamclm.accounts400.ondemand.com/saml2/metadata/dev-jamclm.accounts400.ondemand.com",
    issuer: "kora-dev.sap.com"
  },
  # test2: us-west-1 AWS env
  %{
    server: "jam.test2.sapkora.ca",
    base: "https://jam.test2.sapkora.ca",
    idp_metadata_url: "https://dev-jamclm.accounts400.ondemand.com/saml2/metadata/dev-jamclm.accounts400.ondemand.com",
    issuer: "kora-test-jam.sap.com"
  },
  %{
    server: "qa.test2.sapkora.ca",
    base: "https://qa.test2.sapkora.ca",
    idp_metadata_url: "https://dev-jamclm.accounts400.ondemand.com/saml2/metadata/dev-jamclm.accounts400.ondemand.com",
    issuer: "kora-test-qa.sap.com"
  },
  # test3: eu-central-1 AWS env
  %{
    server: "jam.test3.sapkora.ca",
    base: "https://jam.test3.sapkora.ca",
    idp_metadata_url: "https://dev-jamclm.accounts400.ondemand.com/saml2/metadata/dev-jamclm.accounts400.ondemand.com",
    issuer: "kora-test-jam.sap.com"
  },
  %{
    server: "qa.test3.sapkora.ca",
    base: "https://qa.test3.sapkora.ca",
    idp_metadata_url: "https://dev-jamclm.accounts400.ondemand.com/saml2/metadata/dev-jamclm.accounts400.ondemand.com",
    issuer: "kora-test-qa.sap.com"
  },
  %{
    server: "actual-prod.test2.sapkora.ca",
    base: "http://actual-prod.test2.sapkora.ca",
    idp_metadata_url: "https://accounts400.sap.com/saml2/metadata/accounts.sap.com",
    issuer: "jamclm.sap.com"
  },
  %{
    server: "localhost",
    base: "https://localhost:443",
    idp_metadata_url: "https://dev-jamclm.accounts400.ondemand.com/saml2/metadata/dev-jamclm.accounts400.ondemand.com",
    issuer: "kora-prod-local.sap.com"
  }
]
# tenant info could be provided by a service later on.
# Until then:
# hostname = server <> sub_domain
# where sub_domain is either blank or starts with "."
config :login_proxy, :sub_domain, ""
config :login_proxy, tenants: [
  %{
    server: "localhost",
    name: "Tenant1",
    uuid: "dddddddd-1ab1-1bc1-1de1-ffffffffffff",
    service_provider_issuer: "issuer1"
  },
  %{
    server: "qalocalhost",
    name: "QA Tenant",
    uuid: "c75ebed8-b329-4584-afc9-fbc9549e9646",
    service_provider_issuer: "issuer1"
  },
]
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
