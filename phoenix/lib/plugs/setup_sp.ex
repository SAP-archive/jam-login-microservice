defmodule LoginProxy.SetupSp do
  require Logger
  import Plug.Conn

  def init(opts), do: opts


  def call(conn, opts) do
    {:ok, sp, idp} = LoginProxy.EsamlSetup.setup_esaml()

    conn
    |> assign(:sp, sp)
    |> assign(:idp, idp)
  end
end
