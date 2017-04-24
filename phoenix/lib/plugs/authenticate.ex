defmodule LoginProxy.Authenticate do
  require Logger
  import Plug.Conn

  def init(opts), do: opts


  def call(conn, opts) do
    {:ok, sp, idp} = LoginProxy.EsamlSetup.setup_esaml()

    if authenticated?(conn) || no_auth_path?(conn, opts) do
      conn
      |> assign(:sp, sp)
      |> assign(:idp, idp)
    else
      # redirect conn, to: "/saml/auth"
      conn
      |> put_resp_header("content-type", "text/html")
      |> send_resp(401, "Please log in first.")
      |> halt
    end
  end

  # Check session and make sure it has not expired.
  defp authenticated?(conn) do
    case get_session(conn, :session_id) do
      nil -> false
      uuid -> LoginProxy.SessionStore.load(uuid)
    end
  end

  defp no_auth_path?(conn, opts) do
    conn.request_path in (opts[:no_auth_paths] || [])
  end
end
