defmodule ArweaveSdkEx.Tx do
  use Export.Python
  alias ArweaveSdkEx.Utils.Crypto
  alias __MODULE__

  @cwd File.cwd!()
  @prefix_deep_hash %{list: "list", blob: "blob"}
  @py_files @cwd <> "/lib/python"

  @note_size 32
  @max_chunk_size 256 * 1024

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
        } = tx
      ) do
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
    signature_data_list = [
      # format
      Integer.to_string(2),
      # jwk-n
      Crypto.url_decode64(tx.owner),
      # target target is zero when only to store data
      Crypto.url_decode64(tx.target),
      # quantity
      tx.quantity,
      # reward
      tx.reward,
      # last tx
      Crypto.url_decode64(tx.last_tx),
      # [["Content-Type", "application/elixir"]],
      gen_tag_list(tx.tags),
      # the data
      tx.data_size,
      # data root TODO: calculate it in Elixir
      tx.data_root
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

    payload = do_deep_hash(@prefix_deep_hash.list, size_data)
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

  # When data is bytes
  def get_root_hash(data) do
    root_node =
      chunk(data)
      |> chunk_to_leaf_node()
      |> build_layers()

    root_node.id
  end

  defp chunk(data, start_range \\ 0, all_chunk \\ [])

  defp chunk("", _start_range, all_chunk) do
    all_chunk
  end

  defp chunk(data, start_range, all_chunk) do
    len = byte_size(data)

    if len < @max_chunk_size do
      [gen_chunk_data(data, start_range) | all_chunk]
    else
      first = binary_part(data, 0, @max_chunk_size)

      first_chunk = gen_chunk_data(first, start_range)

      [
        first_chunk
        | chunk(
            binary_part(data, @max_chunk_size, len - @max_chunk_size),
            first_chunk.max_byte_range,
            all_chunk
          )
      ]
    end
  end

  defp gen_chunk_data(data, start_range) do
    data_hash = Crypto.sha256(data)
    len = byte_size(data)

    %{
      data_hash: data_hash,
      data_size: len,
      min_byte_range: start_range,
      max_byte_range: start_range + len
    }
  end

  defp chunk_to_leaf_node(chunk_data) do
    chunk_data
    |> Enum.map(fn data ->
      id =
        [
          hash(data.data_hash),
          data.max_byte_range |> int_to_buffer() |> hash()
        ]
        |> hash()

      data
      |> Map.put(:type, "leaf")
      |> Map.put(:id, id)
    end)
  end

  defp build_layers(nodes, level \\ 0)

  defp build_layers(nodes, _level) when length(nodes) <= 2 do
    hash_branch(nodes)
  end

  defp build_layers(nodes, level) do
    node_pairs = Enum.chunk_every(nodes, 2)

    build_layers(Enum.map(node_pairs, &hash_branch/1), level + 1)
  end

  defp hash_branch(pairs) when length(pairs) == 1 do
    [left] = pairs

    left
  end

  defp hash_branch(pairs) do
    [left, right] = pairs

    id =
      hash([
        hash(left.id),
        hash(right.id),
        left.max_byte_range |> int_to_buffer() |> hash()
      ])

    %{
      id: id,
      type: "branch",
      byte_range: left.max_byte_range,
      max_byte_range: right.max_byte_range,
      left_child: left,
      right_child: right
    }
  end

  defp hash(data) when is_list(data) do
    hash(Enum.join(data))
  end

  defp hash(data) do
    Crypto.sha256(data)
  end

  defp int_to_buffer(num, index \\ @note_size, buffer \\ <<>>)

  defp int_to_buffer(_num, 0, buffer) do
    buffer
  end

  defp int_to_buffer(num, index, buffer) do
    remained = Integer.mod(num, 256)

    int_to_buffer(
      floor((num - remained) / 256),
      index - 1,
      <<remained::integer-size(8)>> <> buffer
    )
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
