defmodule ArweaveSdkEx.Wallet do
  @moduledoc """
    Wallet Operations about Arweave!
  """
  alias ArweaveSdkEx.Tx
  alias ArweaveSdkEx.Utils.Crypto

  @doc """
    > read_jwk_from_file > sign > ArweaveSdkEx.send

    this func is same as sign(self) in arweave-python-client.

    impl of verifier in python:

    > https://www.dlitz.net/software/pycrypto/api/2.6/Crypto.Signature.PKCS1_PSS-module.html

  """

  @spec sign_tx(String.t(), String.t(), map(), map(), integer()) :: {%Tx{}, String.t()}
  def sign_tx(node, data, tags, jwk_json, reward_coefficient) do
    {:ok, last_tx_id} = ArweaveSdkEx.get_last_tx_id(node)
    {:ok, reward} = ArweaveSdkEx.get_reward(node, data, reward_coefficient)
    tx_unsigned = Tx.build_tx(jwk_json, data, tags, last_tx_id, reward)
    sig_unsigned = get_raw_sig(tx_unsigned)
    sig_bytes = Crypto.sign(sig_unsigned, jwk_json)
    id = get_id(sig_bytes)
    tx_signed =
      tx_unsigned
      |> Map.put(:signature, Crypto.url_encode64(sig_bytes))
      |> Map.put(:id, id)
      |> Tx.encode_tx()
    {tx_signed, id, tx_unsigned}
  end

  def get_raw_sig(tx_unsigned) do
    %Tx{}
    |> ExStructTranslator.map_to_struct(tx_unsigned)
    |> Tx.get_unsigned_payload()
  end

  def get_id(sig_bytes) do
    sig_bytes
    |> Crypto.sha256()
    |> Crypto.url_encode64()
  end

  def read_jwk_json_from_file(file_path) do
    file_path
    |> File.read!()
    |> ExStructTranslator.str_to_atom_map()
  end

end
