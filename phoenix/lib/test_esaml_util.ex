defmodule LoginProxy.Test.EsamlUtil do
  require LoginProxy.Records
  def load_metadata(_idp_metadata_url) do
    LoginProxy.Records.esaml_idp_metadata(
      login_location: 'https://accounts400.sap.com/saml2/idp/sso/accounts.sap.com')
  end
end
