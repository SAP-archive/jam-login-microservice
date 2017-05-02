defmodule LoginProxy.SamlController do
  use LoginProxy.Web, :controller
  require LoginProxy.Records
  alias LoginProxy.Records
  require Logger

  # TODO: login to be removed and replaced with auth
  def login(conn, _params) do
    Logger.debug "Previous session uuid: " <> inspect(get_session(conn, :session_id))
    # Check if logged in. If yes, just refresh, otherwise create a session.
    case get_session(conn, :session_id) do      
      nil ->
        uuid = (:uuid.uuid4() |> :uuid.to_string() |> to_string) # erlang string to elixir string
        :ok = LoginProxy.SessionStore.save(uuid, 
          %{"email" => "sam@sap.com", "firstname" => "Sam", "lastname" => "Doe"})
        conn = put_session(conn, :session_id, uuid)
        text conn, "You are now logged in!"
      uuid ->
        LoginProxy.SessionStore.refresh(uuid)
        text conn, "You are already logged in."
    end
  end

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
        # Save session
        uuid = :uuid.uuid4() |> :uuid.to_string() |> to_string
        :ok = LoginProxy.SessionStore.save(uuid, 
          %{"username" => username, "email" => email, "firstname" => firstname, "lastname" => lastname})
        conn = put_session(conn, :session_id, uuid)
        # Get saved request path
        key = LoginProxy.Authenticate.relay_state_key(params["RelayState"])
        Logger.debug "Getting original url from RelayState: " <> inspect(params["RelayState"])
        redirect_path =
        case LoginProxy.Redis.command(["GET", key]) do
          {:ok, redirect_path} ->
            {:ok, _} = LoginProxy.Redis.command(["DEL", key])
            redirect_path
          {:error, reason} ->
            Logger.error("Relay state load failed: " <> reason)
            "/"
        end
        Logger.debug "Redirecting to original URL: " <> inspect(redirect_path)
        # Redirect to original URL
        redirect conn, external: redirect_path
    end
  end
end
