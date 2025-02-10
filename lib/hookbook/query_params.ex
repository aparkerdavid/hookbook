defmodule Hookbook.QueryParams do
  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket
  alias __MODULE__.Spec

  defmacro __using__(_opts) do
    quote do
      on_mount({unquote(__MODULE__), :init})

      import unquote(__MODULE__), only: [query_param: 2]
      alias unquote(__MODULE__)
    end
  end

  defmacro query_param(key, opts) do
    quote do
      on_mount({unquote(__MODULE__), {unquote(key), unquote(opts)}})
    end
  end

  def on_mount(:init, _params, _session, socket) do
    socket
    |> init()
    |> then(&{:cont, &1})
  end

  def on_mount({key, opts}, _params, _session, socket) do
    socket
    |> track(key, opts)
    |> then(&{:cont, &1})
  end

  def track(%Socket{} = socket, key, opts) do
    specs = get_private(socket, :specs)

    spec = %Spec{key: key, opts: opts}

    socket
    |> set_private(:specs, [spec | specs])
    |> update_value(spec, %{})
  end

  def changes(%Socket{} = socket) do
    previous_values = get_private(socket, :previous_values)
    values = get_private(socket, :values)

    for {key, value} <- previous_values, reduce: %{} do
      changes -> Map.put(changes, key, from: value, to: values[key])
    end
  end

  def values(%Socket{} = socket), do: get_private(socket, :values)

  def init(%Socket{} = socket) do
    if get_private(socket) do
      socket
    else
      socket
      |> LiveView.attach_hook(
        __MODULE__.HandleParams,
        :handle_params,
        &handle_params/3
      )
      |> set_private(:values, %{})
      |> set_private(:previous_values, %{})
      |> set_private(:specs, [])
    end
  end

  def handle_params(_params, uri, socket) do
    query_params = query_params(uri)

    socket
    |> handle_query_params(query_params)
    |> then(&{:cont, &1})
  end

  def handle_query_params(socket, params) do
    specs = get_private(socket, :specs)

    socket = set_private(socket, :previous_values, %{})

    for spec <- specs, reduce: socket do
      socket -> update_value(socket, spec, params)
    end
  end

  def update_value(socket, %Spec{} = spec, query_params) do
    previous_value = get_private(socket, :values)[spec.key]
    value = decode_spec(spec, query_params)

    socket =
      if previous_value != value do
        set_previous_value(socket, spec.key, previous_value)
      else
        socket
      end

    set_value(socket, spec.key, value)
  end

  defp query_params(uri) do
    if query = uri |> URI.parse() |> Map.get(:query) do
      URI.decode_query(query)
    else
      %{}
    end
  end

  def decode_param(value, type) do
    case type do
      :string -> value
      :integer -> String.to_integer(value)
      :float -> String.to_float(value)
      :boolean -> String.to_existing_atom(value)
      :sort -> decode_sort(value)
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

  defp set_value(socket, key, value) do
    values =
      socket
      |> get_private(:values)
      |> Map.put(key, value)

    set_private(socket, :values, values)
  end

  defp set_previous_value(socket, key, value) do
    previous_values =
      socket
      |> get_private(:previous_values)
      |> Map.put(key, value)

    set_private(socket, :previous_values, previous_values)
  end

  def decode_spec(%Spec{key: key, opts: opts}, query_params) do
    type = Keyword.get(opts, :type, :string)
    default = Keyword.get(opts, :default)

    if param = Map.get(query_params, "#{key}") do
      decode_param(param, type)
    else
      default
    end
  end

  defp get_private(socket), do: socket.private[:hookbook_query_params]
  defp get_private(socket, key), do: get_private(socket)[key]

  defp set_private(socket, key, value) do
    private = get_private(socket) || %{}

    LiveView.put_private(socket, :hookbook_query_params, Map.put(private, key, value))
  end
end
