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
  metadata: [:request_id]

# esaml
config :login_proxy, :esaml,
  base: "http://some.kora.sapkora.com",
  key_file: "JAM_CLM_KEY.pem",
  cert_file: "JAM_CLM.pem",
  idp_metadata_url: "https://accounts400.sap.com/saml2/metadata/accounts.sap.com"

config :login_proxy, :redis,
  pool_size: 5,
  key_prefix: "LOGIN::PROXY::",
  redix: [
    host: "localhost",
    port: 6379
  ]

config :login_proxy, :remote_app,
  browser_server: [url: "http://browser.sapjam.com:8080"],
  api_server: [url: "http://api.sapjam.com:8080"]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
