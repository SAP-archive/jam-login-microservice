defmodule LoginProxy.Router do
  use LoginProxy.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug LoginProxy.SetTenant
    plug LoginProxy.Authenticate,
      no_auth_paths: ~w(/health /auth/login /auth/logout /auth/saml /auth/saml_consume /auth/saml_metadata)
  end

  pipeline :api do
    plug :accepts, ["json"]
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
    pipe_through :browser

    get "/saml", SamlController, :auth
    get "/saml_metadata", SamlController, :metadata
    post "/saml_consume", SamlController, :consume

    get "/logout", SamlController, :logout
  end

  # API: Ensure login, then forward to the API server.
  scope "/api", LoginProxy do
    pipe_through :api

    forward "/", ApiForwarder, [remote_app: :api_server]
  end

  # Everthing else: Ensure login, then forward to the browser server.
  scope "/", LoginProxy do
    pipe_through :browser # Use the default browser stack

    forward "/", BrowserForwarder, [remote_app: :browser_server]
  end
end
