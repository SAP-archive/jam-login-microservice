defmodule LoginProxy.SamlControllerTest do
  use LoginProxy.ConnCase
  alias LoginProxy.HttpMock

  setup %{conn: conn} do
    {:ok, _} = HttpMock.start()
    {:ok, sp, _idp} = LoginProxy.EsamlSetup.setup_esaml(%{base: "http://jam.test2.sapkora.ca", 
                     idp_metadata_url: "https://accounts400.sap.com/saml2/metadata/accounts.sap.com", 
                     issuer: "jamclm.sap.com"})
    conn = Plug.Conn.assign(conn, :sp, sp)
    {:ok, conn: conn}
  end

  test "Redirect for root", %{conn: conn} do
    conn = get conn, "/"
    assert redirected_to(conn) =~ ~r{^/ui$}
  end

  test "Redirect for index.html", %{conn: conn} do
    conn = get conn, "/index.html"
    assert redirected_to(conn) =~ ~r{^/ui/index.html$}
  end

  test "AuthnRequest", %{conn: conn} do
    conn = get conn, "/auth/logout"
    conn = get conn, "/job"
    assert redirected_to(conn) =~ ~r{/auth/saml\?RelayState=.+}
    # Follow redirect.
    conn = get conn, redirected_to(conn)
    assert redirected_to(conn) =~ ~r{https://accounts400.sap.com/saml2/idp/sso/accounts.sap.com\?.*SAMLRequest=.+}
  end

  test "Consume SAML response", %{conn: conn} do
    {:ok, saml_response} = File.read "test/fixtures/sample_response.txt"
    relay_state = LoginProxy.Authenticate.save_current_url(conn)
    conn = get conn, "/auth/logout"
    conn = post conn, "/auth/saml_consume", %{
      "SAMLResponse" => saml_response,
      "RelayState" => relay_state
    }
    assert html_response(conn, 302) =~ "<html><body>You are being <a href=\"http://www.example.com/\">redirected</a>.</body></html>"
    # It should have a session
    assert Plug.Conn.get_session(conn, :session_id) =~ ~r/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

    # Now that we have authenticated, let's try to forward a request
    HttpMock.set_response(%{
      status_code: 200,
      body: "<html><body>ConversationServiceBuild</body></html>",
      headers: %{hdrs: [{"content-type", "text/html"}]}
    })

    conn = get conn, "/job/ConversationServiceBuild/"
    assert html_response(conn, 200) =~ "ConversationServiceBuild"
    #IO.puts "Headers: " <> inspect(conn.req_headers)
    assert [auth_header] = Plug.Conn.get_req_header(conn, "authentication")
    #IO.puts "auth_header: " <> inspect(auth_header)
    assert auth_header =~ ~r/^Bearer /
    token = auth_header |> String.split() |> Enum.at(1)
    {:ok, user} = KorAuth.Jwt.verify_token(token, Application.get_env(:login_proxy, :jwt_hs256_secret))
    assert %{"email" => "sudhir.rao01@sap.com", "firstname" => "Sudhir", "lastname" => "Rao", "username" => "I832806"} = user
  end
end
