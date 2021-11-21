defmodule ArweaveSdkEx do
  @moduledoc """
    Interact with Arweave network.
  """
  alias ArweaveSdkEx.Utils.ExHttp
  alias ArweaveSdkEx.Tx

  @path %{
    info: "/info",
    tx: "/tx",
    content: "/",
    last_tx: "/tx_anchor",
    price: "/price/"
  }

  def send(node, tx) do
    # Reason: Jason is alphanumeric key order here.
    encoded_data = Jason.encode!(ExStructTranslator.struct_to_map(tx))
    case ExHttp.post(node <> @path.tx, encoded_data, :resp_plain, :without_encode) do
      {:ok, %{status_code: 200}} ->
        {:ok, "success submit tx"}
      error_msg ->
        {:error, inspect(error_msg)}
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

  @spec get_tx(binary, binary) :: {:error, binary} | {:ok, map()}
  def get_tx(node, tx_id) do
    case ExHttp.get(node <> @path.tx <> "/" <> tx_id) do
      {:ok, %{"tags" => tags} = raw_data} ->
        {:ok, %{decoded_tags: decode_tags(tags), raw_data: raw_data}}
      else
        error -> {:error, inspect(others)}
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
    # {:ok, "zMfZtdel-4Z5bft4rm9yztn9oTlAy_ghBFNdgGzVZFhyk1Q4zU_9C_2LKAcHSp5M"}
  end

  def get_reward(node, data, reward_coefficient) do
    size = Tx.get_data_size(data)
    {:ok, ori_reward} = ExHttp.get(node <> @path.price <> size, :plain)
    reward =
      ori_reward
      |> String.to_integer()
      |> Kernel.*(reward_coefficient)
      |> Integer.to_string()
    {:ok, reward}
    # {:ok, "58590163"}
  end

end
