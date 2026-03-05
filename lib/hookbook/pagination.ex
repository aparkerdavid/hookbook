defmodule Hookbook.Pagination do
  alias Phoenix.LiveView
  alias Hookbook.QueryParams

  @event "#{__MODULE__}"
  @prev @event <> ":prev"
  @next @event <> ":next"
  @page @event <> ":page"

  def prev, do: @prev
  def next, do: @next
  def page, do: @page

  defmacro __using__(_opts) do
    quote do
      alias unquote(__MODULE__)
      on_mount({Hookbook.QueryParams, :init})
      on_mount({Hookbook.QueryParams, {:page, [type: :integer, default: 1, assign: true]}})
      on_mount(unquote(__MODULE__))
    end
  end

  def on_mount(_, _params, _session, socket) do
    socket
    |> LiveView.attach_hook(__MODULE__, :handle_event, &handle_event/3)
    |> then(&{:cont, &1})
  end

  def handle_event(@next, _params, socket) do
    socket
    |> QueryParams.merge(%{page: socket.assigns.page + 1})
    |> then(&{:halt, &1})
  end

  def handle_event(@prev, _params, socket) do
    page = if socket.assigns.page > 1, do: socket.assigns.page - 1, else: 1

    socket
    |> QueryParams.merge(%{page: page})
    |> then(&{:halt, &1})
  end

  def handle_event(@page, %{"page" => page}, socket) do
    socket
    |> QueryParams.merge(%{page: page})
    |> then(&{:halt, &1})
  end

  def handle_event(_event, _params, socket) do
    {:cont, socket}
  end
end
