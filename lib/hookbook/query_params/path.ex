defmodule Hookbook.QueryParams.Path do
  alias Hookbook.QueryParams.PrivateData
  alias Hookbook.QueryParams.Encoding

  def merge(socket, values) do
    path = PrivateData.get(socket, :path)

    specs = PrivateData.get(socket, :specs)

    values =
      socket
      |> PrivateData.get(:values)
      |> Map.merge(values)

    build_path(path, specs, values)
  end

  def drop(socket, keys) do
    path = PrivateData.get(socket, :path)

    specs = PrivateData.get(socket, :specs)

    values =
      socket
      |> PrivateData.get(:values)
      |> Map.drop(keys)

    build_path(path, specs, values)
  end

  def set(socket, values) do
    path = PrivateData.get(socket, :path)

    specs = PrivateData.get(socket, :specs)

    build_path(path, specs, values)
  end

  defp build_path(path, specs, values) do
    query_params = if Enum.any?(values), do: Encoding.encode_params(values, specs)

    path
    |> URI.parse()
    |> Map.put(:query, query_params)
    |> URI.to_string()
  end
end
