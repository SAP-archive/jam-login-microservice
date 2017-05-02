defmodule LoginProxy.SamlControllerTest do
  use LoginProxy.ConnCase
  require LoginProxy.Records
  alias LoginProxy.Records
  alias LoginProxy.HttpMock

  defp esaml_env(key) do
    Application.get_env(:login_proxy, :esaml)[key]
  end

  setup %{conn: conn} do
    {:ok, _} = HttpMock.start()

    priv_key = :esaml_util.load_private_key(esaml_env(:key_file) |> to_charlist)
    cert = :esaml_util.load_certificate(esaml_env(:cert_file) |> to_charlist)
    base = esaml_env(:base) |> to_charlist
    fingerprints = ['C9:AF:D5:C0:45:11:81:A8:A6:3C:20:6E:E1:31:D0:68:08:44:96:7F']
    sp = :esaml_sp.setup(Records.esaml_sp(
      key: priv_key,
      certificate: cert,
      trusted_fingerprints: fingerprints,
      idp_signs_envelopes: false,
      consume_uri: base ++ '/saml/consume',
      metadata_uri: 'jamclm.sap.com',
      org: Records.esaml_org(
        name: 'SAP JAM CLM',
        displayname: 'Kora',
        url: base
      ),
      tech: Records.esaml_contact(
        name: 'Ben Yip',
        email: 'b.yip@sap.com'
      )
    ))
    conn = Plug.Conn.assign(conn, :sp, sp)
    {:ok, conn: conn}
  end

  test "Consume SAML response", %{conn: conn} do
    {:ok, saml_response} = File.read "test/fixtures/sample_response.txt"
    relay_state = LoginProxy.Authenticate.save_current_path("/original")
    conn = get conn, "/auth/logout"
    conn = post conn, "/auth/saml_consume", %{
      "SAMLResponse" => saml_response,
      "RelayState" => relay_state
    }
    assert html_response(conn, 302) =~ "<html><body>You are being <a href=\"/original\">redirected</a>.</body></html>"
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
    user = LoginProxy.Jwt.verify_token(token)
    assert %{"email" => "sudhir.rao01@sap.com", "firstname" => "Sudhir", "lastname" => "Rao", "username" => "I832806"} = user
  end
end
