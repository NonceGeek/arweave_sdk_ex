defmodule ArweaveSdkEx.Utils.Crypto do

  def sign(msg, jwk_json) do
    #  JOSE.JWK.from_binary(File.read!(file_path))
    priv =
      jwk_json
      |> get_jwk_from_json()
      |> jwk_to_priv()
    do_sign(msg, priv)
  end

  def get_jwk_from_json(jwk_json) do
    jwk_json
    |> Poison.encode!()
    |> JOSE.JWK.from_binary()
  end

  def jwk_to_priv(jwk) do
    %JOSE.JWK{kty: {_, priv}} = jwk
    priv
  end

  def do_sign(msg, priv) do
    :public_key.sign(
      msg,
      :sha256,
      priv,
      [rsa_padding: :rsa_pkcs1_pss_padding, rsa_pss_saltlen: -1]
    )
  end

  def sha384(data), do: :crypto.hash(:sha384, data)
  def sha256(data), do: :crypto.hash(:sha256, data)

  def url_encode64(data), do: Base.url_encode64(data, padding: false)
  def url_decode64(data), do: Base.url_decode64!(data, padding: false)

end
