defmodule ArweaveSdkEx.Utils.Crypto do
  @jws_ps256 %{ "alg" => "PS256"}

  def sign(msg, jwk) do
    #  JOSE.JWK.from_binary(File.read!(file_path))
    rsa_private_jwk =
      jwk
      |> Poison.encode!()
      |> JOSE.JWK.from_binary()
    do_sign(msg,rsa_private_jwk)
  end

  defp do_sign(msg, rsa_private_jwk) do
    {_, %{"signature" => sig}} =
      JOSE.JWK.sign(msg, @jws_ps256, rsa_private_jwk)
    sig
  end

  def sha384(data), do: :crypto.hash(:sha384, data)
  def sha256(data), do: :crypto.hash(:sha256, data)

  def url_encode64(data), do: Base.url_encode64(data, padding: false)
  def url_decode64(data), do: Base.url_decode64!(data, padding: false)
end
