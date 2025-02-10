defmodule Hookbook.QueryParams.PathTest do
  use ExUnit.Case
  doctest Hookbook.QueryParams.Path
  alias Hookbook.QueryParams.Path
  alias Hookbook.QueryParams
  alias Phoenix.LiveView

  @socket %LiveView.Socket{private: %{lifecycle: %{handle_params: []}}, router: true}

  describe "merge" do
    test "merges query params into path" do
      socket = @socket

      socket =
        socket
        |> QueryParams.init()
        |> QueryParams.track(:foo, type: :string)
        |> QueryParams.track(:baz, type: :integer)

      {:cont, socket} = QueryParams.handle_params(%{}, "/route/parameter/123?foo=bar", socket)

      assert "/route/parameter/123?baz=42&foo=bar" = Path.merge(socket, %{baz: 42})
      assert "/route/parameter/123?foo=baz" = Path.merge(socket, %{foo: "baz"})
    end
  end

  describe "drop" do
    test "drops query params from path" do
      socket = @socket

      socket =
        socket
        |> QueryParams.init()
        |> QueryParams.track(:foo, type: :string)
        |> QueryParams.track(:baz, type: :integer)

      {:cont, socket} =
        QueryParams.handle_params(%{}, "/route/parameter/123?foo=bar&baz=42", socket)

      assert "/route/parameter/123?foo=bar" = Path.drop(socket, [:baz])
      assert "/route/parameter/123?baz=42" = Path.drop(socket, [:foo])
    end
  end

  describe "set" do
    test "sets query params in path" do
      socket = @socket

      socket =
        socket
        |> QueryParams.init()
        |> QueryParams.track(:foo, type: :string)
        |> QueryParams.track(:baz, type: :integer)

      {:cont, socket} =
        QueryParams.handle_params(%{}, "/route/parameter/123?foo=bar&baz=42", socket)

      assert "/route/parameter/123?foo=baz" = Path.set(socket, %{foo: "baz"})
      assert "/route/parameter/123?baz=99&foo=bar" = Path.set(socket, %{baz: 99, foo: "bar"})
      assert "/route/parameter/123?baz=99" = Path.set(socket, %{baz: 99})
      assert "/route/parameter/123" = Path.set(socket, %{})
    end
  end
end
