defmodule LoginProxy.SetupSp do
  require Logger
  import Plug.Conn

  def init(opts), do: opts


  def call(conn, opts) do
    idp_info = select_idp(conn)
    Logger.info "IDP metadata #{inspect idp_info}"
    {:ok, sp, idp} = LoginProxy.EsamlSetup.setup_esaml(idp_info)

    conn
    |> assign(:sp, sp)
    |> assign(:idp, idp)
  end

  def select_idp(conn) do
    host = conn.host
    port = Integer.to_string(conn.port)
    Logger.info "Host in request is: #{host} Port is: #{port}"
    domain =  if ( port in ["0", "80", "443"] ) do
                host
              else 
                host <> ":" <> port 
              end
    Logger.info "Domain is: #{domain}"
    Enum.find(Application.get_env(:login_proxy, :idps), fn t -> t.server == domain end)
  end  
end
