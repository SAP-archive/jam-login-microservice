defmodule LoginProxy.SetTenant do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    # Get hostname from http request
    hostname = "host1.com" # TODO: fix me
    tenant = Enum.find(Application.get_env(:login_proxy, :tenants), fn t -> t.hostname == hostname end)
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
