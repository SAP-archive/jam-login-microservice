defmodule LoginProxy.SamlSign.Test do
  use ExUnit.Case
  require Logger

  setup do
    {:ok, sp, _idp} = LoginProxy.EsamlSetup.setup_esaml(%{base: "http://jam.test2.sapkora.ca", 
                     idp_metadata_url: "https://accounts400.sap.com/saml2/metadata/accounts.sap.com", 
                     issuer: "jamclm.sap.com"})
    {:ok, sp: sp}
  end

  test "verify SAML response", %{sp: sp} do
    # Read fixture with SAML response data
    {:ok, saml_response} = File.read "test/fixtures/sample_response.txt"
    # Pass it to esaml for verification
    xml = :esaml_binding.decode_response(nil, saml_response)
    # IO.puts "XML: " <> inspect(xml)
    # The signature should match
    assert {:ok, _assertion} = LoginProxy.SamlVerify.validate_assertion(xml, fn _x, _y -> :ok end, sp, true)
    # The content should have expected information
    #IO.puts "Assertion " <> inspect(assertion)
  end
end
