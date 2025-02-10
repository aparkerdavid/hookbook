defmodule Hookbook.QueryParams do
  alias Phoenix.Component
  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket
  alias __MODULE__.Spec
  alias __MODULE__.PrivateData
  alias __MODULE__.Path
  alias __MODULE__.Encoding

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

  def merge(socket, query_params, opts \\ []) do
    opts = [{:to, Path.merge(socket, query_params)} | opts]

    socket
    |> LiveView.push_patch(opts)
    |> then(&{:cont, &1})
  end

  def drop(socket, keys, opts \\ []) do
    opts = [{:to, Path.drop(socket, keys)} | opts]

    socket
    |> LiveView.push_patch(opts)
    |> then(&{:cont, &1})
  end

  def set(socket, query_params, opts \\ []) do
    opts = [{:to, Path.set(socket, query_params)} | opts]

    socket
    |> LiveView.push_patch(opts)
    |> then(&{:cont, &1})
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
    specs = PrivateData.get(socket, :specs)

    spec = %Spec{key: key, opts: opts}

    socket
    |> PrivateData.put(:specs, [spec | specs])
    |> update_value(spec, %{})
  end

  def changes(%Socket{} = socket) do
    previous_values = PrivateData.get(socket, :previous_values)
    values = PrivateData.get(socket, :values)

    for {key, value} <- previous_values, reduce: %{} do
      changes -> Map.put(changes, key, from: value, to: values[key])
    end
  end

  def values(%Socket{} = socket), do: PrivateData.get(socket, :values)

  def init(%Socket{} = socket) do
    if PrivateData.get(socket) do
      socket
    else
      socket
      |> LiveView.attach_hook(
        __MODULE__.HandleParams,
        :handle_params,
        &handle_params/3
      )
      |> PrivateData.put(:values, %{})
      |> PrivateData.put(:previous_values, %{})
      |> PrivateData.put(:specs, [])
    end
  end

  def handle_params(_params, uri, socket) do
    %URI{} = uri = URI.parse(uri)
    query_params = query_params(uri)
    path = uri.path

    socket
    |> handle_query_params(query_params)
    |> PrivateData.put(:path, path)
    |> then(&{:cont, &1})
  end

  def handle_query_params(socket, params) do
    specs = PrivateData.get(socket, :specs)

    socket = PrivateData.put(socket, :previous_values, %{})

    for spec <- specs, reduce: socket do
      socket -> update_value(socket, spec, params)
    end
  end

  def update_value(socket, %Spec{} = spec, query_params) do
    previous_value = PrivateData.get(socket, :values)[spec.key]
    value = decode_spec(spec, query_params)

    assign_key =
      case spec.opts[:assign] do
        key when is_boolean(key) -> key && spec.key
        key when is_atom(key) -> key
        _ -> nil
      end

    socket =
      if previous_value != value do
        set_previous_value(socket, spec.key, previous_value)
      else
        socket
      end

    socket = set_value(socket, spec.key, value)

    if assign_key do
      Component.assign(socket, assign_key, value)
    else
      socket
    end
  end

  defp query_params(%URI{query: query}) do
    if query do
      URI.decode_query(query)
    else
      %{}
    end
  end

  defp set_value(socket, key, value) do
    values =
      socket
      |> PrivateData.get(:values)
      |> Map.put(key, value)

    PrivateData.put(socket, :values, values)
  end

  defp set_previous_value(socket, key, value) do
    previous_values =
      socket
      |> PrivateData.get(:previous_values)
      |> Map.put(key, value)

    PrivateData.put(socket, :previous_values, previous_values)
  end

  def decode_spec(%Spec{key: key, opts: opts}, query_params) do
    type = Keyword.get(opts, :type, :string)
    default = Keyword.get(opts, :default)

    if param = Map.get(query_params, "#{key}") do
      Encoding.decode(param, type)
    else
      default
    end
  end
end
