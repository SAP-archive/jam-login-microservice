defmodule LoginProxy.EsamlSetup do
  require Logger
  require LoginProxy.Records
  alias LoginProxy.Records

  def init(opts), do: opts

  defp esaml_env(key) do
    Application.get_env(:login_proxy, :esaml)[key]
  end

  def setup_esaml() do
    Logger.debug("setup_esaml")
    priv_key = :esaml_util.load_private_key(esaml_env(:key_file) |> to_charlist)
    cert = :esaml_util.load_certificate(esaml_env(:cert_file) |> to_charlist)
    base = esaml_env(:base) |> to_charlist
    fingerprints = ['C9:AF:D5:C0:45:11:81:A8:A6:3C:20:6E:E1:31:D0:68:08:44:96:7F']

    sp = :esaml_sp.setup(Records.esaml_sp(
      key: priv_key,
      certificate: cert,
      trusted_fingerprints: fingerprints,
      consume_uri: base ++ '/auth/saml_consume',
      metadata_uri: 'jamclm.sap.com', # this is the "issuer" in authn request
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
    idp = Application.get_env(:login_proxy, :esaml)[:esaml_util].load_metadata(esaml_env(:idp_metadata_url) |> to_charlist)

    #Logger.debug("sp, idp: \n" <> inspect(sp) <> "\n\n" <> inspect(idp))
    {:ok, sp, idp}
  end
end
