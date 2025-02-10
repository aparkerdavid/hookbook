defmodule Hookbook.QueryParams.Encoding do
  alias __MODULE__.Protocol

  def encode(nil, _type), do: nil

  def encode(%{__struct__: module} = value, module) do
    if Protocol.impl_for(%{__struct__: module}) do
      Protocol.encode(value)
    end
  end

  def encode(value, type) do
    case type do
      :string -> value
      :integer -> Integer.to_string(value)
      :float -> Float.to_string(value)
      :boolean -> if value, do: "true", else: "false"
      :sort -> encode_sort(value)
    end
  end

  def decode(value, type) do
    dummy = %{__struct__: type}

    if Protocol.impl_for(dummy) do
      Protocol.decode(dummy, value)
    else
      case type do
        :string -> value
        :integer -> String.to_integer(value)
        :float -> String.to_float(value)
        :boolean -> String.to_existing_atom(value)
        :sort -> decode_sort(value)
      end
    end
  end

  defp decode_sort(value) do
    [direction, field] = String.split(value, ":")

    direction =
      case direction do
        "asc" -> :asc
        "desc" -> :desc
      end

    field = String.to_existing_atom(field)

    {direction, field}
  end

  def encode_params(data, specs) do
    data
    |> Enum.map(fn {key, value} ->
      type = find_type(specs, key)
      {"#{key}", encode(value, type)}
    end)
    |> Enum.filter(fn {_key, value} -> value != nil end)
    |> Enum.into(%{})
    |> URI.encode_query()
  end

  defp find_type(specs, key) do
    if spec = Enum.find(specs, &(&1.key == key)) do
      spec.opts[:type]
    else
      raise "No type found for key: #{key}"
    end
  end

  defp encode_sort({direction, field}) do
    "#{direction}:#{field}"
  end
end
