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

  def auth(conn, _params) do
    req = conn.adapter |> elem(1)
    login_location = Records.esaml_idp_metadata(conn.assigns.idp, :login_location)
    signed_xml = conn.assigns.sp.generate_authn_request(login_location)
    IO.puts "XML: " <> inspect(:lists.flatten(:xmerl.export([signed_xml], :xmerl_xml)))
    {:ok, _} = :esaml_cowboy.reply_with_authnreq(conn.assigns.sp, login_location, "foo", req)
    conn |> put_status(:temporary_redirect) |> Map.put(:state, :sent)
  end

  def consume(conn, _params) do
    req = conn.adapter |> elem(1)
    case :esaml_cowboy.validate_assertion(conn.assigns.sp, &:esaml_util.check_dupe_ets/2, req) do
      {:ok, assertion, _relaystate, _} ->
        attrs = Records.esaml_assertion(assertion.attributes)
        uid = :proplists.get_value(:uid, attrs)
        Logger.debug("Saml attributes: " <> inspect(attrs))
        Logger.debug("Saml uid: " <> inspect(uid))
        # Process the successful login
        render conn, "index.html"

      {:error, reason, _} ->
        conn |> send_resp(403, "Access denied, assertion failed validation: " <> inspect(reason))
    end
  end
end
