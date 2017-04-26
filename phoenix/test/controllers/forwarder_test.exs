defmodule LoginProxy.ForwarderTest do
  use LoginProxy.ConnCase
  alias LoginProxy.HttpMock

  setup %{conn: conn} do
    {:ok, _} = HttpMock.start()
    HttpMock.set_response(%{
      status_code: 200,
      body: "<html><body>ConversationServiceBuild</body></html>",
      headers: %{hdrs: [{"content-type", "text/html"}]}
    })

    {:ok, conn: conn}
  end

  test "GET /job/ConversationServiceBuild/", %{conn: conn} do
    conn = get conn, "/auth/login"
    conn = get conn, "/job/ConversationServiceBuild/"
    assert html_response(conn, 200) =~ "ConversationServiceBuild"
    # Validate that a GET request to the url was made internally
    assert %{method: :get, url: "https://clm-ci.mo.sap.corp/job/ConversationServiceBuild/"}
    = HttpMock.get_request()
  end

  test "GET /job/ConversationServiceBuild/ (auth failure)", %{conn: conn} do
    conn = get conn, "/auth/logout"
    conn = get conn, "/job/ConversationServiceBuild/"
    assert html_response(conn, 401) =~ "Please log in first."
  end
end
