defmodule ArweaveSdkEx do
  @moduledoc """
  Documentation for `ArweaveSdkEx`.
  """
  alias ArweaveSdkEx.Utils.ExHttp

  @path %{
    info: "/info",
    tx: "/tx/",
    content: "/",
  }
  def network_available?(node) do
    case ExHttp.get_once(node <> @path.info) do
      {:ok, _} ->
        true
      _ ->
        false
    end
  end

  def get_tx(node, tx_id) do
    case ExHttp.get(node <> @path.tx <>tx_id) do
      {:ok, %{"tags" => tags}} ->
        {:ok, decode_tags(tags)}
      others ->
        {:error, inspect(others)}
    end
  end

  def get_content_in_tx(node, tx_id) do
    case ExHttp.get_with_redirect(node <> @path.content <> tx_id) do
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
end
