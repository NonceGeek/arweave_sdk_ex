defmodule ArweaveSdkEx.Wallet do
  alias ArweaveSdkEx.Tx
  alias ArweaveSdkEx.Utils.Crypto
  def sign(data, priv_key) do
    data
    |> Crypto.sign(priv_key)
    |> Base.url_encode64()
  end


end
