defmodule ArweaveSdkEx.Tx do

  use Export.Python
  alias ArweaveSdkEx.Utils.Crypto
  alias __MODULE__

  @prefix_deep_hash %{list: "list", blob: "blob"}
  @py_files "lib/python"

  defstruct reward: "",
    owner: "",
    target: <<>>,
    tags: %{},
    data: <<>>,
    last_tx: <<>>,
    data_root: <<>>,
    signature: <<>>,
    quantity: "0",
    format: 2,
    data_tree: [],
    data_size: <<>>,
    id: <<>>

  @doc """
    get_last_tx_id by ArweaveSdkEx.get_last_tx_id(node).
  """
  def build_tx(%{n: n} = _jwk, data, tags, last_tx_id, reward, python_path) do
    encoded_data = Crypto.url_encode64(data)

    data_root_hash = get_root_hash(encoded_data, python_path)
    %Tx{
      data: encoded_data,
      data_root: data_root_hash,
      tags: tags,
      last_tx: last_tx_id,
      owner: n,
      reward: reward,
      data_size: get_data_size(data)
    }
  end

  def encode_tx(
    %{
      tags: tags,
      data_root: data_root_hash
    } = tx) do
    tx
    |> Map.put(:tags, format_tags(tags))
    |> Map.put(:data_root, Crypto.url_encode64(data_root_hash))
  end

  def format_tags(raw_tags) do
    Enum.map(raw_tags, fn {key, value} ->
      %{
        name: Crypto.url_encode64(key),
        value: Crypto.url_encode64(value)
      }
    end)
  end
  def get_unsigned_payload(%Tx{} = tx)
    when tx.format == 2 do
      IO.puts inspect gen_tag_list(tx.tags)
      signature_data_list =
        [
          Integer.to_string(2), # format
          Crypto.url_decode64(tx.owner), # jwk-n
          Crypto.url_decode64(tx.target), # target target is zero when only to store data
          tx.quantity, # quantity
          tx.reward, # reward
          Crypto.url_decode64(tx.last_tx),  # last tx
          # [["Content-Type", "application/elixir"]],
          gen_tag_list(tx.tags),
          tx.data_size, # the data
          tx.data_root, # data root TODO: calculate it in Elixir
        ]
      # signature_data_list
      deep_hash(signature_data_list)
  end

  def gen_tag_list(tags) do
    Enum.map(tags, fn {key, value} ->
      [key, value]
    end)
  end

  def deep_hash(data) when is_list(data) do
    size_data =
      data
      |> Enum.count()
      |> Integer.to_string()
    payload =
      do_deep_hash(@prefix_deep_hash.list, size_data)
    deep_hash(data, payload, :chunks)
  end

  def deep_hash(data) do
    size_data_str =
      data
      |> byte_size()
      |> Integer.to_string()
    @prefix_deep_hash.blob
    |> do_deep_hash(size_data_str)
    |> Kernel.<>(Crypto.sha384(data))
    |> Crypto.sha384()
  end

  def do_deep_hash(prefix, size_data) do
    prefix
    |> Kernel.<>(size_data)
    |> Crypto.sha384()
  end


  def deep_hash(chunks, acc, :chunks)
    when chunks == [] do
      acc
  end
  def deep_hash(chunks, acc, :chunks) do
    {[payload], others} = Enum.split(chunks, 1)
    new_acc =
      acc
      |> Kernel.<>(deep_hash(payload))
      |> Crypto.sha384()
    deep_hash(others, new_acc, :chunks)
  end

  def get_data_size(data) do
    data
    |> byte_size()
    |> Integer.to_string()
  end

  # def encode_tx_to_json_in_spec_way(tx) do
  #   tx_without_tags =
  #     tx
  #     |> ExStructTranslator.struct_to_map()
  #     |> Enum.reject(fn {key, _value} ->
  #       key == :tags
  #     end)
  #     |> Enum.into(%{})
  #   tx_without_tags
  #   Poison.encode!(tx_without_tags)
  # end

  # def encode_tags_to_json() do
  # end
  # +-------------+
  # | funcs of py |
  # +-------------+
  def get_root_hash(data, python_path) do
    {:ok, py} = Python.start(python: python_path, python_path: Path.expand(@py_files))
    val = Python.call(py, get_root_hash(data), from_file: "get_root_hash")
    Python.stop(py)
    val
  end

  # def encode_map_in_alphanumeric_key_order(obj) do
  #   az_keys = obj |> Map.keys |> Enum.sort
  #   iodata = [
  #     "{",
  #     Enum.map(az_keys, fn k ->
  #       v = obj[k]
  #       [Poison.encode!(k), ":", encode_object_in_alphanumeric_key_order(v)]
  #     end) |> Enum.intersperse(","),
  #     "}"
  #   ]
  #   IO.iodata_to_binary(iodata)
  # end
end
