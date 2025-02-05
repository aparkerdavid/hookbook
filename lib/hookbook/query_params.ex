defmodule Hookbook.QueryParams do
  alias Phoenix.Component
  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket

  def on_mount(spec, _params, _session, socket) do
    socket
    |> assign_spec(spec)
    |> then(&{:cont, &1})
  end

  def assign_spec(%Socket{} = socket, spec) do
    %{assigns: assigns} = socket = ensure_init(socket)

    socket
    |> Component.assign(
      query_params: Map.put(assigns[:query_params], List.first(spec), default_value(spec))
    )
    |> LiveView.put_private(
      :hookbook_query_params,
      socket.private[:hookbook_query_params]
      |> Map.put(:specs, [spec | socket.private[:hookbook_query_params].specs])
    )
    |> LiveView.attach_hook(
      {__MODULE__, List.first(spec)},
      :handle_params,
      query_param_handler(spec)
    )
  end

  def ensure_init(%Socket{} = socket) do
    private = socket.private[:hookbook_query_params] || %{changes: %{}, specs: []}

    socket
    |> ensure_clear_changes_handler()
    |> LiveView.put_private(:hookbook_query_params, private)
    |> Component.assign_new(:query_params, fn -> %{} end)
  end

  def query_param_handler([key | opts]) do
    fn _params, uri, %{assigns: assigns} = socket ->
      query_params = query_params(uri)

      type = Keyword.get(opts, :type, :string)
      default = Keyword.get(opts, :default)

      value =
        if param = Map.get(query_params, "#{key}") do
          decode_query_param(param, type)
        else
          default
        end

      previous_value = assigns.query_params[key]

      private =
        if value != previous_value do
          put_in(socket.private[:hookbook_query_params], [:changes, key],
            from: previous_value,
            to: value
          )
        else
          socket.private[:hookbook_query_params]
        end

      socket
      |> LiveView.put_private(:hookbook_query_params, private)
      |> Component.assign(query_params: Map.put(assigns.query_params, key, value))
      |> then(&{:cont, &1})
    end
  end

  def query_params(uri) do
    if query = uri |> URI.parse() |> Map.get(:query) do
      URI.decode_query(query)
    else
      %{}
    end
  end

  def decode_query_param(value, type) do
    case type do
      :string -> value
      :integer -> String.to_integer(value)
      :float -> String.to_float(value)
      :boolean -> String.to_existing_atom(value)
    end
  end

  defp default_value([_key | opts]), do: Keyword.get(opts, :default)

  defp ensure_clear_changes_handler(socket) do
    handlers = socket.private[:lifecycle][:handle_params]

    if Enum.any?(handlers, &(&1.id == __MODULE__.ClearChanges)) do
      socket
    else
      LiveView.attach_hook(
        socket,
        __MODULE__.ClearChanges,
        :handle_params,
        &clear_changes/3
      )
    end
  end

  defp clear_changes(_params, _uri, socket) do
    private = (socket.private[:hookbook_query_params] || %{}) |> Map.put(:changes, %{})

    socket
    |> LiveView.put_private(:hookbook_query_params, private)
    |> then(&{:cont, &1})
  end
end
