defmodule LoginProxy.SamlVerify do
  import LoginProxy.Records

  def validate_assertion(xml, duplicateFun, sp, allowStale) do
    ns = [{'samlp', 'urn:oasis:names:tc:SAML:2.0:protocol'},
          {'saml', 'urn:oasis:names:tc:SAML:2.0:assertion'}]
    :esaml_util.threaduntil([
        fn x ->
          case :xmerl_xpath.string('/samlp:Response/saml:Assertion', x, [{:namespace, ns}]) do
              [a] -> a;
              _ -> {:error, :bad_assertion}
          end
        end,
        fn a ->
          if esaml_sp(sp, :idp_signs_envelopes) do
            case __MODULE__.verify(xml, esaml_sp(sp, :trusted_fingerprints)) do
              :ok -> a
              outerError -> {:error, {:envelope, outerError}}
            end;
          else
            a
          end
        end,
        fn a ->
          if esaml_sp(sp, :idp_signs_assertions) do
            case __MODULE__.verify(a, esaml_sp(sp, :trusted_fingerprints)) do
              :ok -> a
              innerError -> {:error, {:assertion, innerError}}
            end;
          else
            a
          end
        end,
        fn a ->
          case :esaml.validate_assertion(a, esaml_sp(sp, :consume_uri), esaml_sp(sp, :metadata_uri)) do
            {:ok, ar} -> ar
            {:error, :stale_assertion} -> if allowStale, do: {:ok, a}, else: {:error, :stale_assertion}
            {:error, reason} -> {:error, reason}
          end
        end,
        fn ar ->
          case duplicateFun.(ar, :xmerl_dsig.digest(xml)) do
            :ok -> ar
            _ -> {:error, :duplicate}
          end
        end
    ], xml)
  end

  def verify(element, fingerprints) do
    dsns = [{'ds', 'http://www.w3.org/2000/09/xmldsig#'},
        {'ec', 'http://www.w3.org/2001/10/xml-exc-c14n#'}]

    [alg] = :xmerl_xpath.string('ds:Signature/ds:SignedInfo/ds:SignatureMethod/@Algorithm', element, [{:namespace, dsns}])
    signatureMethodAlgorithm = alg
    |> xmlAttribute(:value)
    {hashFunction, _, _} = signature_props(signatureMethodAlgorithm)

    # Verify attribute 
    [alg]= :xmerl_xpath.string('ds:Signature/ds:SignedInfo/ds:CanonicalizationMethod/@Algorithm', element, [{:namespace, dsns}])
    signatureMethodAlgorithm = alg
    |> xmlAttribute(:value)
    'http://www.w3.org/2001/10/xml-exc-c14n#' = signatureMethodAlgorithm

    [alg] = :xmerl_xpath.string('ds:Signature/ds:SignedInfo/ds:SignatureMethod/@Algorithm', element, [{:namespace, dsns}])
    signatureMethodAlgorithm = alg
    |> xmlAttribute(:value)
    'http://www.w3.org/2000/09/xmldsig#rsa-sha1' = signatureMethodAlgorithm

    [c14nTx] = :xmerl_xpath.string('ds:Signature/ds:SignedInfo/ds:Reference/ds:Transforms/ds:Transform[@Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"]', element, [{:namespace, dsns}])

    inclNs = case :xmerl_xpath.string('ec:InclusiveNamespaces/@PrefixList', c14nTx, [{:namespace, dsns}]) do
        [] -> []
        path -> xmlAttribute(path, :value) |> :string.tokens(' ,')
    end

    canonXmlUtf8 =
    :xmerl_c14n.c14n(strip_element(element), false, inclNs)
    |> :unicode.characters_to_binary(:unicode, :utf8)
    canonSha = :crypto.hash(hashFunction, canonXmlUtf8)

    [cs2] =
    :xmerl_xpath.string('ds:Signature/ds:SignedInfo/ds:Reference/ds:DigestValue/text()', element, [{:namespace, dsns}])
    canonSha2 = cs2
    |> xmlText(:value)
    |> :base64.decode()

    if canonSha != canonSha2 do
      {:error, :bad_digest}
    else
      [sigInfo] = :xmerl_xpath.string('ds:Signature/ds:SignedInfo', element, [{:namespace, dsns}])
      sigInfoCanon = :xmerl_c14n.c14n(sigInfo)
      data = :erlang.list_to_binary(sigInfoCanon)

      # HACK ALERT: esaml only does c14n inclusive canonicalization
      # and we need exclusive: http://www.w3.org/2001/10/xml-exc-c14n#
      # For now, strip assertion attribute and leave the other one intact.
      data = Regex.replace(~r/ xmlns=.*assertion"/, data, "")

      [sign] =
      :xmerl_xpath.string('ds:Signature//ds:SignatureValue/text()', element, [{:namespace, dsns}])
      sig = sign
      |> xmlText(:value) 
      |> :base64.decode()

      [cb] =
      :xmerl_xpath.string('ds:Signature//ds:X509Certificate/text()', element, [{:namespace, dsns}])
      certBin = cb
      |> xmlText(:value)
      |> :base64.decode()
      certHash = :crypto.hash(:sha, certBin)
      certHash2 = :crypto.hash(:sha256, certBin)

      cert = :public_key.pkix_decode_cert(certBin, :plain)
      keyBin =
      certificate(cert, :tbsCertificate)
      |> tBSCertificate(:subjectPublicKeyInfo)
      |> subjectPublicKeyInfo(:subjectPublicKey)
      key = :public_key.pem_entry_decode({:'RSAPublicKey', keyBin, :not_encrypted})

      # IO.puts "Going to verify. data, hashfunction, sig, key: \n" <> inspect(data) <> "\n\n"
      # <> inspect(hashFunction) <> "\n\n" <> inspect(sig) <> "\n\n" <> inspect(key) <> "\n\n"
      case :public_key.verify(data, hashFunction, sig, key) do
        true ->
          case fingerprints do
            :any ->
                :ok
            prints ->
              case Enum.any?(prints, fn x -> x in [certHash, {:sha, certHash}, {:sha256, certHash2}] end) do
                true ->
                  :ok
                false ->
                  {:error, :cert_not_accepted}
              end
          end
        false ->
          {:error, :bad_signature}
      end
    end
  end

  defp signature_props('http://www.w3.org/2000/09/xmldsig#rsa-sha1'), do: signature_props(:rsa_sha1)
  defp signature_props(:rsa_sha1) do
    hashFunction = :sha
    digestMethod = 'http://www.w3.org/2000/09/xmldsig#sha1'
    url = 'http://www.w3.org/2000/09/xmldsig#rsa-sha1'
    {hashFunction, digestMethod, url}
  end
  defp signature_props('http://www.w3.org/2001/04/xmldsig-more#rsa-sha256'), do: signature_props(:rsa_sha256)
  defp signature_props(:rsa_sha256) do
    hashFunction = :sha256
    digestMethod = 'http://www.w3.org/2001/04/xmlenc#sha256'
    url = 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256'
    {hashFunction, digestMethod, url}
  end

  defp strip_element(element) do
    newKids =
    xmlElement(element, :content)
    |> Enum.filter(fn kid ->
      case :xmerl_c14n.canon_name(kid) do
        'http://www.w3.org/2000/09/xmldsig#Signature' -> false
        name -> true
      end
    end)
    xmlElement(element, content: newKids)
  end
end
