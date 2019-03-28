defmodule LoginProxy.Authenticate do
  require Logger
  import Plug.Conn

  def init(opts), do: opts


  def call(conn, opts) do
    {authenticated, conn} = get_authenticated_user(conn)
    cond do
      authenticated -> # Generate auth header with JWT containing logged in user
        auth_header = "Bearer " <> KorAuth.Jwt.create_token(conn.assigns.user, Application.get_env(:korauth, :jwt_hs256_secret))
        conn |> put_req_header("authentication", auth_header)

      no_auth_path?(conn, opts) -> conn # continue

      true -> maybe_redirect_for_sso(conn)
    end
  end

  defp maybe_redirect_for_sso(conn) do
    if xhr?(conn) || !accept_html?(conn) do
      # do not redirect ajax and asset requests; return unauthorized status and a header
      conn
      |> put_resp_header("not-authenticated", "true")
      |> put_resp_header("content-type", "application/json")
      |> send_resp(:unauthorized, ~s/{"error": {"message": "Unauthorized", "code": 401}}/)
      |> halt
    else
      # redirect otherwise
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
    scheme = if Application.get_env(:login_proxy, LoginProxy.Endpoint)[:ssl_scheme_enabled], do: "https", else: "http"
    url = scheme <> "://" <> conn.host <> port <> conn.request_path
    Logger.info "Saving RelayState with url: " <> url
    relay_state = UUID.uuid4()
    LoginProxy.RelayState.save(relay_state, url)
    relay_state
  end

  # Get user from session and set it in conn.
  # Return true if authenticated and the updated conn.
  defp get_authenticated_user(conn) do
    case get_session(conn, :session_id) do
      nil -> {false, conn}
      uuid -> 
        with {:ok, user} <- LoginProxy.SessionStore.load(uuid) do
          {true, conn |> assign(:user, user)}
        else
          _ -> {false, put_session(conn, :session_id, nil)}
        end
    end
  end

  defp no_auth_path?(conn, opts) do
    conn.request_path in (opts[:no_auth_paths] || [])
  end

  defp xhr?(conn), do: "XMLHttpRequest" in get_req_header(conn, "x-requested-with")

  defp accept_html?(conn) do
    get_req_header(conn, "accept") |> Enum.any?(fn h -> h =~ ~r{text/html} end)
  end
end
