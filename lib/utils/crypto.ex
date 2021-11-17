defmodule ArweaveSdkEx.Utils.Crypto do
  @jws_ps256 %{ "alg" => "PS256"}

  def sign(msg, rsa_priv_json_str) do
    rsa_private_jwk = JOSE.JWK.from_binary(rsa_priv_json_str)
    do_sign(msg,rsa_private_jwk)
  end

  defp do_sign(msg, rsa_private_jwk) do
    {_, %{"signature" => sig}} =
      JOSE.JWK.sign(msg, @jws_ps256, rsa_private_jwk)
    sig
  end

  def sha384(data), do: :crypto.hash(:sha384, data)
end
