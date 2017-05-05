defmodule LoginProxy.LoginMock do
  import Plug.Conn
  import Plug.Test

  def login(conn) do
    uuid = (:uuid.uuid4() |> :uuid.to_string() |> to_string) # erlang string to elixir string
    :ok = LoginProxy.SessionStore.save(uuid, 
      %{"email" => "sam@sap.com", "firstname" => "Sam", "lastname" => "Doe"})
    conn
    |> init_test_session([])
    |> put_session(:session_id, uuid)
  end
end
