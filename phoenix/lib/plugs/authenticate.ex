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
      # Save current url in Redis
      relay_state = save_current_url(conn)
      # Redirect
      Logger.debug "Redirecting to: " <> "/auth/saml?RelayState=#{relay_state}"
      Phoenix.Controller.redirect(conn, external: "/auth/saml?RelayState=#{relay_state}")
      |> halt
    end
  end

  def save_current_url(conn) do
    port = if conn.port == 80, do: "", else: ":" <> to_string(conn.port)
    url = to_string(conn.scheme) <> "://" <> conn.host <> port <> conn.request_path
    Logger.info "Saving RelayState with url: " <> url
    relay_state = :uuid.uuid4() |> :uuid.to_string() |> to_string
    LoginProxy.RelayState.save(relay_state, url)
    relay_state
  end

  # Get user from session and set it in conn.
  # Return true if authenticated and the updated conn.
  defp get_authenticated_user(conn) do
    case get_session(conn, :session_id) do
      nil ->
        conn = fetch_query_params(conn)
        case Map.get(conn.query_params, "RelayState") do
          nil -> {false, conn}
          relay_state ->
            with {:ok, uuid} <- LoginProxy.RelayState.load(relay_state),
              {:ok, user} <- LoginProxy.SessionStore.load(uuid)
            do
              conn = put_session(conn, :session_id, uuid)
              {true, conn |> assign(:user, user)}
            else
              _ -> {false, conn}
            end
        end
      uuid -> 
        with {:ok, user} <- LoginProxy.SessionStore.load(uuid)
        do
          {true, conn |> assign(:user, user)}
        else
          _ -> {false, put_session(conn, :session_id, nil)}
        end
    end
  end

  defp no_auth_path?(conn, opts) do
    conn.request_path in (opts[:no_auth_paths] || [])
  end
end
