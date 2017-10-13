defmodule LoginProxy.SetupSpTest do
  use LoginProxy.ConnCase
  alias LoginProxy.SetupSp

  setup %{conn: conn} do
    {:ok, conn: conn}
  end


  test "setting up idp", %{conn: conn} do
    idp_info = SetupSp.select_idp(conn)
    assert idp_info.base == "http://jam.test2.sapkora.ca"
    assert idp_info.idp_metadata_url == "https://accounts400.sap.com/saml2/metadata/accounts.sap.com"
    assert idp_info.issuer == "jamclm.sap.com"
  end

end