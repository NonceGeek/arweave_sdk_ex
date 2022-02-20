defmodule ArweaveSdkEx.CodeRunner do
  @moduledoc """
    Run codes storage in arweave TX.
  """
  def get_ex_by_tx_id(node, tx_id) do
    {:ok, %{decoded_tags: decoded_tags}} =ArweaveSdkEx.get_tx(node, tx_id)
    type = Map.get(decoded_tags, :"Content-Type")

    if_record = has_if_record(decoded_tags)
    case do_get_ex_by_tx_id(node, tx_id, type) do
      {:ok, content} ->
        {:ok, %{code: content, if_record: if_record}}
      {:error, msg} ->
        {:error, msg}
    end
  end

  defp do_get_ex_by_tx_id(node, tx_hash, "application/elixir") do
    {:ok, %{content: content}} = ArweaveSdkEx.get_content_in_tx(node, tx_hash)
    {:ok, content}
  end

  defp do_get_ex_by_tx_id(_node, _tx_id, _other_type) do
    {:error, "it's not a elixir func"}
  end

  def has_if_record(decoded_tags) do
    raw_res = Map.get(decoded_tags, "If-Record")
    if is_nil(raw_res) or raw_res=="0" do
      false
    else
      true
    end
  end

  # +--------+
  # | runner |
  # +--------+

  def run_ex(code, params_map) do
    params_list = Map.to_list(params_map)
    {result, _} = Code.eval_string(code, params_list, __ENV__)
    %{output: result, input: params_map}
  end

  def run_func(mod_name, func_name, params) do
    func_name_atom = String.to_atom(func_name)
    "Elixir.#{mod_name}"
    |> String.to_atom()
    |> apply(func_name_atom, params)
    |> Enum.into(%{})
  end
end
