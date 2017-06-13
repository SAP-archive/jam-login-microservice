defmodule LoginProxy.Authenticate do
  require Logger
  import Plug.Conn

  def init(opts), do: opts


  def call(conn, opts) do
    {authenticated, conn} = get_authenticated_user(conn)
    if authenticated || no_auth_path?(conn, opts) do
      # Generate auth header with JWT containing logged in user
      conn = if Map.get(conn.assigns, :user) do
        auth_header = "Bearer " <> LoginProxy.Jwt.create_token(conn.assigns.user)
        conn |> put_req_header("authentication", auth_header)
      else
        conn
      end
    else
      # Save current path in Redis
      relay_state = save_current_path(conn.request_path)
      # Redirect
      Logger.debug "Redirecting to: " <> "/auth/saml?RelayState=#{relay_state}"
      Phoenix.Controller.redirect(conn, external: "/auth/saml?RelayState=#{relay_state}")
      |> halt
    end
  end

  def save_current_path(path) do
    Logger.debug "Saving RelayState with url: " <> path
    relay_state = :uuid.uuid4() |> :uuid.to_string() |> to_string
    key = relay_state_key(relay_state)
    {:ok, "OK"} = LoginProxy.Redis.command(["SET", key, path])
    relay_state
  end

  def relay_state_key(relay_state) do
    LoginProxy.Redis.prefix() <> "::RELAY::" <> relay_state
  end

  # Get user from session and set it in conn.
  # Return true if authenticated and the updated conn.
  defp get_authenticated_user(conn) do
    case get_session(conn, :session_id) do
      nil -> {false, conn}
      uuid -> 
        user = LoginProxy.SessionStore.load(uuid)
        if user do
          {true, conn |> assign(:user, user)}
        else
          {false, put_session(conn, :session_id, nil)}
        end
    end
  end

  defp no_auth_path?(conn, opts) do
    conn.request_path in (opts[:no_auth_paths] || [])
  end
end
