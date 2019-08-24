defmodule LoginProxy.Jwt do
  use Joken.Config

  def create_token(extra_claims, hs256_secret) do
    signer = Joken.Signer.create("HS256", hs256_secret)
    generate_and_sign!(extra_claims, signer)
  end
  
  def verify_token(token, hs256_secret) do
    signer = Joken.Signer.create("HS256", hs256_secret)
    verify_and_validate(token, signer)
  end
end
