defmodule LoginProxy.Router do
  use LoginProxy.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :put_secure_browser_headers
    plug LoginProxy.SetTenant
    plug LoginProxy.Authenticate,
      no_auth_paths: ~w(/health)
  end

  pipeline :auth do
    plug :fetch_session
    plug :put_secure_browser_headers
    plug Plug.Parsers,
      parsers: [:urlencoded, :multipart, :json],
      pass: ["*/*"],
      json_decoder: Jason
    plug LoginProxy.SetTenant
    plug LoginProxy.SetupSp
  end

  pipeline :api do
    plug :accepts, ["json","html"]
    plug :fetch_session
    plug LoginProxy.SetTenant
    plug LoginProxy.Authenticate
  end

  # This scope is just for local test.
  scope "/login_proxy", LoginProxy do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/health", LoginProxy do
    pipe_through :browser

    get "/", HealthController, :health
  end

  scope "/auth", LoginProxy do
    pipe_through :auth

    get "/saml", SamlController, :auth
    get "/saml_metadata", SamlController, :metadata
    post "/saml_consume", SamlController, :consume

    get "/logout", SamlController, :logout
  end

  # UI: Ensure login, then forward to the UI server.
  # Note: we redirect "/" and some paths here. See LoginProxy.Endpoint module.
  scope "/ui", LoginProxy do
    pipe_through :browser

    forward "/", BrowserForwarder
  end

  # Everthing else: ensure login, then forward to the api server.
  scope "/", LoginProxy do
    pipe_through :api

    forward "/", ApiForwarder
  end
end
