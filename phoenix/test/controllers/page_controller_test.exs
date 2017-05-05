defmodule LoginProxy.PageControllerTest do
  use LoginProxy.ConnCase

  test "GET /login_proxy (auth failure)", %{conn: conn} do
    conn = get conn, "/auth/logout"
    conn = get conn, "/login_proxy"
    assert html_response(conn, 302) =~ ~r/You are being.*redirected/
  end

  test "GET /login_proxy", %{conn: conn} do
    conn = LoginProxy.LoginMock.login(conn)
    conn = get conn, "/login_proxy"
    assert html_response(conn, 200) =~ "Welcome to Phoenix!"
  end
end
