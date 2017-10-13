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
  browser_server: [url: "http://browser.sapjam.com"],
  api_server: [url: "http://api.sapjam.com:8080"]

config :login_proxy, :http_request_module, LoginProxy.HttpMock

config :login_proxy, :esaml,
  allow_stale: true,
  esaml_util: LoginProxy.Test.EsamlUtil

# Use a fixed secret
config :login_proxy, :jwt_hs256_secret, "cef2699914a2a9ae5c8e2314faceb35ebe9f206eb352b1b13534e7bf2ac22d4f"

config :junit_formatter,
  report_dir: Path.join([Mix.Project.build_path, "..", "..", "test", "reports"])

config :login_proxy, :sub_domain, ".example.com"
config :login_proxy, tenants: [
  %{
    server: "www",
    name: "Tenant1",
    uuid: "50c5a290-146d-4d54-944c-1bfad270718d",
    service_provider_issuer: "issuer1"
  }
]

config :login_proxy, idps: [
  %{
    server: "www.example.com",
    base: "http://jam.test2.sapkora.ca",
    idp_metadata_url: "https://accounts400.sap.com/saml2/metadata/accounts.sap.com",
    issuer: "jamclm.sap.com"
  }
]

