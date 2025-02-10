defmodule Hookbook.QueryParams.PrivateData do
  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket

  def put(%Socket{} = socket, key, value) do
    private = get(socket) || %{}

    LiveView.put_private(socket, :hookbook_query_params, Map.put(private, key, value))
  end

  def get(%Socket{} = socket), do: socket.private[:hookbook_query_params]
  def get(%Socket{} = socket, key), do: get(socket)[key]
end
