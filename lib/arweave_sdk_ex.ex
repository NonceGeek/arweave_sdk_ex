defmodule ArweaveSdkEx do
  @moduledoc """
    Interact with Arweave network.
  """
  alias ArweaveSdkEx.Utils.ExHttp
  alias ArweaveSdkEx.Tx

  @path %{
    info: "/info",
    tx: "/tx/",
    content: "/",
    last_tx: "/tx_anchor",
    price: "/price/"
  }

  def send(node, data) do
    case ExHttp.post(node <> @path.tx, data, :resp_plain) do
      {:ok, %{body: "OK"}} ->
        {:ok, "success"}
      {:error, error_info} ->
        {:error, inspect(error_info)}
    end
  end

  def network_available?(node) do
    case ExHttp.get(node <> @path.info, :once) do
      {:ok, _} ->
        true
      _ ->
        false
    end
  end

  @spec get_tx(binary, binary) :: {:error, binary} | {:ok, any}
  def get_tx(node, tx_id) do
    case ExHttp.get(node <> @path.tx <>tx_id) do
      {:ok, %{"tags" => tags}} ->
        {:ok, decode_tags(tags)}
      others ->
        {:error, inspect(others)}
    end
  end

  def get_content_in_tx(node, tx_id) do
    case ExHttp.get(node <> @path.content <> tx_id, :redirect) do
      {:ok, %{body: content ,headers: headers}} ->
        {:ok, %{content: content, type: get_type(headers)}}
      others ->
        {:error, inspect(others)}
    end
  end

  def decode_tags(tags) do
    tags
    |> ExStructTranslator.to_atom_struct()
    |> Enum.map(fn %{name: name_encoded, value: value_encoded} ->
      {:ok, name} = Base.url_decode64(name_encoded, padding: false)
      {:ok, value} = Base.url_decode64(value_encoded, padding: false)
      {String.to_atom(name), value}
    end)
    |> Enum.into(%{})
  end

  def get_type(headers) do
    headers
    |> Enum.into(%{})
    |> Map.get("Content-Type")
  end

  def get_last_tx_id(node) do
    ExHttp.get(node <> @path.last_tx, :plain)
    # {:ok, "DQi0fnAvdJeOY_ZlFAAqcV3PLVOY5ssV1UOBGgzMkxyAz5MLBorLO5xCrc-Hq-rV"}
  end

  def get_reward(node, data) do
    size = Tx.get_data_size(data)
    ExHttp.get(node <> @path.price <> size, :plain)
    # {:ok, "64958659"}
  end

end
