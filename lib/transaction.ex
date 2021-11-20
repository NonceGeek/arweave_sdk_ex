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
    tags = format_tags(tags)
    %Tx{
      data: encoded_data,
      data_root: Crypto.url_encode64(data_root_hash),
      tags: tags,
      last_tx: last_tx_id,
      owner: n,
      reward: reward,
      data_size: get_data_size(data)
    }
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
      signature_data_list =
        [
          Integer.to_string(2), # format
          Crypto.url_decode64(tx.owner), # jwk-n
          Crypto.url_decode64(tx.target), # target target is zero when only to store data
          tx.quantity, # quantity
          tx.reward, # reward
          Crypto.url_decode64(tx.last_tx),  # last tx
          gen_tag_list(tx.tags),
          tx.data_size, # the data
          Crypto.url_decode64(tx.data_root), # data root TODO: calculate it in Elixir
        ]
      # signature_data_list
      deep_hash(signature_data_list)
  end

  def gen_tag_list(tags) do
    Enum.map(tags, fn %{name: key, value: value}->
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
  # +-------------+
  # | funcs of py |
  # +-------------+
  def get_root_hash(data, python_path) do
    {:ok, py} = Python.start(python: python_path, python_path: Path.expand(@py_files))
    val = Python.call(py, get_root_hash(data), from_file: "get_root_hash")
    Python.stop(py)
    val
  end
end
