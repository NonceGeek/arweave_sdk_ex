defmodule ArweaveSdkEx.Wallet do
  @moduledoc """
    Wallet Operations about Arweave!
  """
  alias ArweaveSdkEx.Tx
  alias ArweaveSdkEx.Utils.Crypto

  @doc """
    read_jwk_from_file > sign > ArweaveSdkEx.send
  """

  def sign_tx(node, data, tags, jwk) do
    {:ok, last_tx_id} = ArweaveSdkEx.get_last_tx_id(node)
    {:ok, reward} = ArweaveSdkEx.get_reward(node, data)
    tx_unsigned = Tx.build_tx(jwk, data, tags, last_tx_id, reward)
    raw_sig = get_raw_sig(tx_unsigned)
    sig = get_sig(jwk, raw_sig)
    id = get_id(sig)

    tx_unsigned
    |> Map.put(:signature, sig)
    |> Map.put(:id, id)
  end

  def get_raw_sig(tx_unsigned) do
    %Tx{}
    |> ExStructTranslator.map_to_struct(tx_unsigned)
    |> Tx.get_unsigned_payload()
  end

  def get_id(sig) do
    sig
    |> Crypto.sha256()
    |> Crypto.url_encode64()
  end

  def get_sig(jwk, raw_sig) do
    raw_sig
    |> Crypto.sign(jwk)
    |> Crypto.url_encode64()
  end

  def read_jwk_from_file(file_path) do
    file_path
    |> File.read!()
    |> ExStructTranslator.str_to_atom_map()
  end

end
