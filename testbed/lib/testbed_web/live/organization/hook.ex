defmodule TestbedWeb.Live.Organization.Hook do
  alias Phoenix.LiveView
  alias Phoenix.Component

  def on_mount(spec, _params, _session, %{assigns: assigns} = socket) do
    private = socket.private[:hookbook_query_params] || %{}
    specs = [spec | private[:specs] || []]

    query_params = assigns[:query_params] || %{}

    socket
    |> LiveView.put_private(
      :hookbook_query_params,
      private |> Map.put(:specs, specs) |> Map.put(:changes, %{})
    )
    |> Component.assign(
      query_params: Map.put(query_params, List.first(spec), default_value(spec))
    )
    |> apply_clear_changes_handler()
    |> LiveView.attach_hook(
      {__MODULE__, List.first(spec)},
      :handle_params,
      query_param_handler(spec)
    )
    |> then(&{:cont, &1})
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

  defp apply_clear_changes_handler(socket) do
    case socket.private do
      %{lifecycle: %Phoenix.LiveView.Lifecycle{handle_params: handlers}} when is_list(handlers) ->
        if Enum.find(handlers, &(&1.id == {__MODULE__.ClearChanges})) do
          socket
        else
          LiveView.attach_hook(
            socket,
            {__MODULE__.ClearChanges},
            :handle_params,
            &clear_changes/3
          )
        end

      _ ->
        socket
    end
  end

  defp clear_changes(_params, _uri, socket) do
    private = (socket.private[:hookbook_query_params] || %{}) |> Map.put(:changes, %{})

    socket
    |> LiveView.put_private(:hookbook_query_params, private)
    |> then(&{:cont, &1})
  end
end
