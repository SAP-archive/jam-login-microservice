defmodule LoginProxy.EsamlSetup do
  import Plug.Conn
  use Application
  require Logger
  require LoginProxy.Records
  alias LoginProxy.Records

  def init(opts), do: opts

  defp esaml_env(key) do
    Application.get_env(:login_proxy, :esaml)[key]
  end

  defp setup_esaml() do
    Logger.debug("setup_esaml")
    priv_key = :esaml_util.load_private_key(esaml_env(:key_file) |> to_charlist)
    cert = :esaml_util.load_certificate(esaml_env(:cert_file) |> to_charlist)
    base = esaml_env(:base) |> to_charlist
    # TODO: set fingerprint we expect from SAP ID. This is a sample fingerprint only.
    fingerprints = ['2d:3a:d5:1e:df:cc:16:bf:cc:39:c1:66:2d:f1:33:71']

    sp = :esaml_sp.setup(Records.esaml_sp(
      key: priv_key,
      certificate: cert,
      trusted_fingerprints: fingerprints,
      consume_uri: 'http://mo-b3aa2dd9e.mo.sap.corp:8808', # base ++ '/saml/consume',
      metadata_uri: 'jamclm.sap.com', # base ++ '/saml/metadata',
      org: Records.esaml_org(
        name: 'SAP JAM CLM',
        displayname: 'Kora',
        url: base
      ),
      tech: Records.esaml_contact(
        name: 'Ben Yip',
        email: 'b.yip@sap.com'
      )
    ))

    # Read IDP's metadata
    idp = :esaml_util.load_metadata(esaml_env(:idp_metadata_url) |> to_charlist)

    #Logger.debug("sp, idp: \n" <> inspect(sp) <> "\n\n" <> inspect(idp))
    {:ok, sp, idp}
  end

  def call(conn, _opts) do
    {:ok, sp, idp} = setup_esaml()
    Map.put(conn, :assigns, %{sp: sp, idp: idp})
    # if authenticated?(conn) do
    #   conn
    # else
    #   conn
    #   |> send_resp(401, "Auth failed")
    #   |> halt
    # end
  end
end
