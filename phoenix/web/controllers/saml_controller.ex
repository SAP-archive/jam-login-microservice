defmodule LoginProxy.SamlController do
  use LoginProxy.Web, :controller
  require LoginProxy.Records
  alias LoginProxy.Records
  require Logger

  def logout(conn, _params) do
    Logger.debug "Previous session uuid: " <> inspect(get_session(conn, :session_id))
    # delete session
    conn =
      case get_session(conn, :session_id) do
        nil -> conn
        uuid ->
          LoginProxy.SessionStore.delete(uuid)
          put_session(conn, :session_id, nil)
      end
    text conn, "You are now logged out."
  end

  def metadata(conn, _params) do
    req = conn.adapter |> elem(1)
    {:ok, _} = :esaml_cowboy.reply_with_metadata(conn.assigns.sp, req)
    conn |> put_status(:ok) |> Map.put(:state, :sent) # already sent via cowboy, so just update conn.state
  end

  def auth(conn, params) do
    login_location = Records.esaml_idp_metadata(conn.assigns.idp, :login_location) |> to_string
    xml = LoginProxy.AuthnRequest.generate_authn_request(conn.assigns.sp, login_location)
    redirect_url = LoginProxy.AuthnRequest.encode_http_redirect(login_location, xml, params["RelayState"])
    conn |> redirect(external: redirect_url)
  end

  def consume(conn, params) do
    xml = :esaml_binding.decode_response(nil, params["SAMLResponse"])
    allow_stale_response = Application.get_env(:login_proxy, :esaml)[:allow_stale]
    case LoginProxy.SamlVerify.validate_assertion(xml, fn _x, _y -> :ok end, conn.assigns.sp, allow_stale_response) do
      {:error, reason} ->
        Logger.error("SAML verify failed. Returning 403.")
        conn
        |> put_status(403)
        |> text("Access denied, assertion failed validation: " <> inspect(reason))
      {:ok, assertion} ->
        # Process the successful login
        attrs = Records.esaml_assertion(assertion, :attributes)
        email = Keyword.get(attrs, :email) |> to_string
        firstname = Keyword.get(attrs, :first_name) |> to_string
        lastname = Keyword.get(attrs, :last_name) |> to_string
        username = assertion |> Records.esaml_assertion(:subject) |> Records.esaml_subject(:name) |> to_string
        Logger.debug "username, email, first, last: \n" <> "#{username}, #{email}, #{firstname}, #{lastname}"
        # Save session and set session cookie
        session_uuid = :uuid.uuid4() |> :uuid.to_string() |> to_string
        :ok = LoginProxy.SessionStore.save(session_uuid,
          %{"username" => username, "email" => email, "firstname" => firstname, "lastname" => lastname})
        conn = put_session(conn, :session_id, session_uuid)
        # Get saved request path
        relay_state = params["RelayState"]
        Logger.debug "Getting original url from RelayState: " <> inspect(relay_state)
        redirect_path =
        with {:ok, url} <- LoginProxy.RelayState.load(relay_state) do
          url
        else
          _ ->
            Logger.error("Relay state load failed for key: #{relay_state}")
            "/"
        end
        Logger.debug "Redirecting to original URL: " <> inspect(redirect_path)
        # Redirect to original URL
        redirect conn, external: redirect_path
    end
  end
end
