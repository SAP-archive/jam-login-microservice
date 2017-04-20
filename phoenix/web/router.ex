defmodule LoginProxy.Router do
  use LoginProxy.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug LoginProxy.EsamlSetup
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LoginProxy do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index

    get "/saml/metadata", PageController, :metadata
    get "/saml/auth", PageController, :auth
    post "/saml/consume", PageController, :consume
  end

  # Other scopes may use custom stacks.
  # scope "/api", LoginProxy do
  #   pipe_through :api
  # end
end
