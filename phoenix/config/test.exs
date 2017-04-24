use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :login_proxy, LoginProxy.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :login_proxy, :redis,
  key_prefix: "TEST::LOGIN::PROXY::"

config :login_proxy, :remote_app,
  browser_server: [url: "https://clm-ci.mo.sap.corp"],
  api_server: [url: "http://api.sapjam.com:8080"]
