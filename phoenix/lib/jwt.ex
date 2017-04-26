defmodule LoginProxy.Jwt do
  import Joken

  @doc """
  Jwt.create_token(claims) -> token

  claims should be a map containing key, value pairs.
  The token will be a signed JWT with the claims readable by the receiver.
  """
  def create_token(claims) do
    claims
    |> token()
    |> with_signer(hs256(Application.get_env(:login_proxy, :jwt)[:hs256_secret]))
    |> sign()
    |> get_compact()
  end

  @doc """
  Jwt.verify_token(token) -> claims

  Token is a JWT signed with the shared secret.
  Returns a map containing claims contained in the token.
  """
  def verify_token(token) do
    token
    |> token()
    |> with_signer(hs256(Application.get_env(:login_proxy, :jwt)[:hs256_secret]))
    |> verify()
    |> get_claims()
  end
end
