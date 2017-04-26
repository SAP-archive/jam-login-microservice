defmodule LoginProxy.Authenticate do
  require Logger
  import Plug.Conn

  def init(opts), do: opts


  def call(conn, opts) do
    {:ok, sp, idp} = LoginProxy.EsamlSetup.setup_esaml()

    {authenticated, conn} = get_authenticated_user(conn)
    if authenticated || no_auth_path?(conn, opts) do
      conn
      |> assign(:sp, sp)
      |> assign(:idp, idp)
    else
      # redirect conn, to: "/auth/saml"
      conn
      |> put_resp_header("content-type", "text/html")
      |> send_resp(401, "Please log in first.")
      |> halt
    end
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
          {false, conn}
        end
    end
  end

  defp no_auth_path?(conn, opts) do
    conn.request_path in (opts[:no_auth_paths] || [])
  end
end
