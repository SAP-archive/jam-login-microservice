defmodule LoginProxy.SetTenant do
  import Plug.Conn
  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    # Get hostname from http request
    hostname = conn.host
    Logger.info "Host in request is: " <> hostname
    sub_domain = Application.get_env(:login_proxy, :sub_domain)
    tenant = Enum.find(Application.get_env(:login_proxy, :tenants), fn t -> t.server <> sub_domain == hostname end)
    {tenant_uuid, issuer} = case tenant do
      nil -> {"UNKNOWN", nil}
      t -> {t.uuid, t.service_provider_issuer}
    end

    conn
    |> assign(:tenant_uuid, tenant_uuid)
    |> put_req_header("tenant_uuid", tenant_uuid)
    |> assign(:issuer, issuer)
  end
end
