defmodule LoginProxy.AuthnRequest do
  import LoginProxy.Records
  import XmlBuilder

  # Our version of authn request. Formats the XML without linefeeds and tabs.
  # Still using records from esaml so we can use the rest of esaml.
  # idp_URL is a string here, not charlist
  def generate_authn_request(sp, idp_URL) do
    metadata_uri = esaml_sp(sp, :metadata_uri)
    consume_uri = esaml_sp(sp, :consume_uri)
    stamp = :erlang.localtime_to_universaltime(:erlang.localtime())
    |> :esaml_util.datetime_to_saml()

    # Build XML
    element("samlp:AuthnRequest", %{
      "Destination": idp_URL,
      "ForceAuthn": "true",
      "AssertionConsumerServiceURL": consume_uri |> to_string,
      "ProtocolBinding": "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST",
      "IssueInstant": stamp,
      "Version": "2.0",
      "ID": "CLM-" <> (:uuid.uuid4() |> :uuid.to_string() |> to_string),
      "xmlns:samlp": "urn:oasis:names:tc:SAML:2.0:protocol",
      "xmlns:saml": "urn:oasis:names:tc:SAML:2.0:assertion"},
      [
        element("saml:Issuer", %{}, [metadata_uri |> to_string]),
        element("samlp:NameIDPolicy", %{
          "xmlns:samlp": "urn:oasis:names:tc:SAML:2.0:protocol",
          "Format": "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent",
          "AllowCreate": "true"}),
        element("samlp:RequestedAuthnContext", %{
          "xmlns:samlp": "urn:oasis:names:tc:SAML:2.0:protocol",
          "Comparison": "exact"}, [
            element("saml:AuthnContextClassRef", %{"xmlns:saml": "urn:oasis:names:tc:SAML:2.0:assertion"}, [
              "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"
            ])
          ]
        )
      ]
    )
    |> generate |> String.replace(~r/\t/, "") |> String.replace(~r/\n/, "")
  end

  # Note: We expect strings as input, not charlists
  def encode_http_redirect(idp_URL, xml, relay_state) do
    # encode the http redirect
    param = :http_uri.encode(:base64.encode_to_string(:zlib.zip(xml |> to_charlist))) |> to_string
    relay_state_esc = :http_uri.encode(relay_state |> to_charlist) |> to_string
    first_param_delimiter = if String.contains?(idp_URL, "?"), do: "&", else: "?"
    idp_URL <> first_param_delimiter <> "SAMLRequest=" <> param <> "&RelayState=" <> relay_state_esc
  end

end
