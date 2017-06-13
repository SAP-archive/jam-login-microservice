defmodule LoginProxy.ForwarderTest do
  use LoginProxy.ConnCase
  alias LoginProxy.HttpMock

  setup %{conn: conn} do
    {:ok, _} = HttpMock.start()

    {:ok, conn: conn}
  end

  test "GET /ui/job/ConversationServiceBuild/", %{conn: conn} do
    HttpMock.set_response(%{
      status_code: 200,
      body: "<html><body>ConversationServiceBuild</body></html>",
      headers: %{hdrs: [{"content-type", "text/html"}]}
    })

    conn = LoginProxy.LoginMock.login(conn)
    conn = get conn, "/ui/job/ConversationServiceBuild/"
    assert html_response(conn, 200) =~ "ConversationServiceBuild"
    # Validate that a GET request to the url was made internally
    request = HttpMock.get_request()
    assert %{method: :get, url: "http://localhost:4050/ui/job/ConversationServiceBuild/"} = request
    assert request.headers[:authentication] =~ "Bearer "
    token = request.headers[:authentication] |> String.split() |> Enum.at(1)
    user = LoginProxy.Jwt.verify_token(token)
    assert %{"email" => _, "firstname" => _, "lastname" => _} = user
    assert "50c5a290-146d-4d54-944c-1bfad270718d" == request.headers[:tenant_uuid]
  end

  test "GET /ui/job/ConversationServiceBuild/ (auth failure)", %{conn: conn} do
    conn = get conn, "/auth/logout"
    conn = get conn, "/ui/job/ConversationServiceBuild/"
    assert html_response(conn, 302) =~ ~r/You are being.*redirected/
  end

  test "GET api /testing/api", %{conn: conn} do
    HttpMock.set_response(%{
      status_code: 200,
      body: ~s({"results": [1,2,3]}),
      headers: %{hdrs: [{"content-type", "application/json"}]}
    })

    conn = LoginProxy.LoginMock.login(conn)
    conn = get conn, "/testing/api"
    assert json_response(conn, 200) == %{"results" => [1,2,3]}
    # Validate that a GET request to the url was made internally
    request = HttpMock.get_request()
    assert %{method: :get, url: "http://localhost:4030/testing/api"} = request
    assert request.headers[:authentication] =~ "Bearer "
    token = request.headers[:authentication] |> String.split() |> Enum.at(1)
    user = LoginProxy.Jwt.verify_token(token)
    assert %{"email" => _, "firstname" => _, "lastname" => _} = user
    assert "50c5a290-146d-4d54-944c-1bfad270718d" == request.headers[:tenant_uuid]
  end

end
