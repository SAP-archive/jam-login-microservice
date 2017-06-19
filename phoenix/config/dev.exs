use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :login_proxy, LoginProxy.Endpoint,
  http: [port: 4050],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []


# Watch static and templates for browser reloading.
config :login_proxy, LoginProxy.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{web/views/.*(ex)$},
      ~r{web/templates/.*(eex)$}
    ]
  ]

# Use a fixed secret
config :login_proxy, :jwt_hs256_secret, "cef2699914a2a9ae5c8e2314faceb35ebe9f206eb352b1b13534e7bf2ac22d4f"

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20
