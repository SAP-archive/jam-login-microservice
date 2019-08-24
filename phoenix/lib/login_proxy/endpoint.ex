defmodule LoginProxy.Endpoint do
  use Phoenix.Endpoint, otp_app: :login_proxy

  socket "/socket", LoginProxy.UserSocket,
    websocket: true,
    longpoll: false

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  #
  # REMOVED static assets serving as it will be done in ui.
  #
  # plug Plug.Static,
  #   at: "/", from: :login_proxy, gzip: false,
  #   only: ~w(css fonts images js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Logger

  # Do not parse the body by default. Do it only in routes that need it.
  # Plug.Parsers removed from here.

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session,
    store: :cookie,
    key: "_login_proxy_key",
    signing_salt: "JOeWNLOh",
    http_only: true,
    secure: Application.get_env(:login_proxy, LoginProxy.Endpoint)[:secure_session]
    

  # ui and other redirects go here. Add to map as needed.
  plug LoginProxy.Redirects, %{"/" => "/ui", "/index.html" => "/ui/index.html"}

  plug LoginProxy.Router
end
