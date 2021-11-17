defmodule ArweaveSdkEx.Tx do
  alias ArweaveSdkEx.Utils.Crypto

  @prefix_deep_hash %{list: "list", blob: "blob"}
  defstruct reward: "",
    owner: "",
    target: "",
    data: "",
    quantity: "",
    last_tx: "",
    signature_data: "",
    format: 2

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
    IO.puts inspect new_acc
    deep_hash(others, new_acc, :chunks)
  end

end
