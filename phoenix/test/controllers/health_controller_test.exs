defmodule LoginProxy.HealthControllerTest do
  use LoginProxy.ConnCase

  test "GET /health", %{conn: conn} do
    conn = get conn, "/health"
    assert json_response(conn, 200) == %{"web" => true, "redis" => true}
  end
end
