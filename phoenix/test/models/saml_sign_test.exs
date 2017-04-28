defmodule LoginProxy.SamlSign.Test do
  use ExUnit.Case
  require LoginProxy.Records
  alias LoginProxy.Records

  defp esaml_env(key) do
    Application.get_env(:login_proxy, :esaml)[key]
  end

  setup do
    priv_key = :esaml_util.load_private_key(esaml_env(:key_file) |> to_charlist)
    cert = :esaml_util.load_certificate(esaml_env(:cert_file) |> to_charlist)
    base = esaml_env(:base) |> to_charlist
    fingerprints = ['C9:AF:D5:C0:45:11:81:A8:A6:3C:20:6E:E1:31:D0:68:08:44:96:7F']
    sp = :esaml_sp.setup(Records.esaml_sp(
      key: priv_key,
      certificate: cert,
      trusted_fingerprints: fingerprints,
      idp_signs_envelopes: false,
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

    {:ok, sp: sp}
  end

  test "verify SAML response", %{sp: sp} do
    # Read fixture with SAML response data
    {:ok, saml_response} = File.read "test/fixtures/sample_response.txt"
    # Pass it to esaml for verification
    xml = :esaml_binding.decode_response(nil, saml_response)
    #IO.puts "XML: " <> inspect(xml)
    # The signature should match
    assert {:ok, _assertion} = LoginProxy.SamlVerify.validate_assertion(xml, fn _x, _y -> :ok end, sp, true)
    # The content should have expected information
    #IO.puts "Assertion " <> inspect(assertion)
  end
end
