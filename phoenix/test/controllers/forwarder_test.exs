defmodule LoginProxy.ForwarderTest do
  use LoginProxy.ConnCase

  test "GET /job/ConversationServiceBuild/", %{conn: conn} do
    conn = get conn, "/auth/login"
    conn = get conn, "/job/ConversationServiceBuild/"
    assert html_response(conn, 200) =~ "ConversationServiceBuild"
  end

  test "GET /job/ConversationServiceBuild/ (auth failure)", %{conn: conn} do
    conn = get conn, "/auth/logout"
    conn = get conn, "/job/ConversationServiceBuild/"
    assert html_response(conn, 401) =~ "Please log in first."
  end
end
