defmodule LoginProxy.LoginMock do
  import Plug.Conn
  import Plug.Test

  def login(conn) do
    uuid = UUID.uuid4()
    :ok = LoginProxy.SessionStore.save(uuid, 
      %{"username" => "I800000", "email" => "sam@sap.com", "firstname" => "Sam", "lastname" => "Doe"})
    conn
    |> init_test_session([])
    |> put_session(:session_id, uuid)
  end
end
