defmodule Hookbook.QueryParamsTest do
  use ExUnit.Case
  alias Hookbook.QueryParams
  alias Phoenix.LiveView

  # a socket that looks as if it were mounted at the router
  @socket %LiveView.Socket{private: %{lifecycle: %{handle_params: []}}, router: true}

  describe "init" do
    test "ensures presence of default values in the :hookbook_query_params key of private data" do
      socket = @socket
      refute socket.private[:hookbook_query_params]

      socket = QueryParams.init(socket)

      assert %{specs: [], previous_values: %{}, values: %{}} =
               socket.private[:hookbook_query_params]
    end

    test "does not trample existing data" do
      socket =
        @socket
        |> Map.put(:assigns, %{query_params: %{foo: "bar"}})
        |> LiveView.put_private(:hookbook_query_params, %{
          values: %{foo: "bar"},
          previous_values: %{foo: "baz"},
          specs: [:foo, type: :string]
        })

      socket = QueryParams.init(socket)

      assert %{
               values: %{foo: "bar"},
               previous_values: %{foo: "baz"},
               specs: [:foo, type: :string]
             } =
               socket.private[:hookbook_query_params]
    end

    test "adds handle_params callback" do
      socket = QueryParams.init(@socket)

      assert [%{id: QueryParams.HandleParams}] = socket.private.lifecycle.handle_params
    end

    test "does not try to duplicate HandleParams callback" do
      socket =
        @socket
        |> QueryParams.init()
        |> QueryParams.init()

      assert [%{id: QueryParams.HandleParams}] = socket.private.lifecycle.handle_params
    end
  end

  describe "track" do
    setup do
      socket = QueryParams.init(@socket)
      %{socket: socket}
    end

    test "adds a spec to the :specs key of private data", %{socket: socket} do
      socket = QueryParams.track(socket, :foo, type: :string)

      assert %{specs: [%QueryParams.Spec{key: :foo, opts: [type: :string]}]} =
               socket.private[:hookbook_query_params]
    end

    test "adds default value to query params", %{socket: socket} do
      socket = QueryParams.track(socket, :foo, type: :string, default: "bar")
      socket = QueryParams.track(socket, :baz, type: :integer)

      assert %{values: %{foo: "bar", baz: nil}} = socket.private[:hookbook_query_params]
    end
  end

  describe "handle_params" do
    setup do
      socket =
        @socket
        |> QueryParams.init()
        |> QueryParams.track(:foo, type: :string)

      %{socket: socket}
    end

    test "handles query params", %{socket: socket} do
      {:cont, socket} =
        QueryParams.handle_params(%{}, "http://localhost:4000/foos/1/bars/42?foo=bar", socket)

      assert %{foo: "bar"} = socket.private[:hookbook_query_params].values
    end

    test "handles base path", %{socket: socket} do
      {:cont, socket} =
        QueryParams.handle_params(%{}, "http://localhost:4000/foos/1/bars/42", socket)

      assert %{path: "/foos/1/bars/42"} = socket.private[:hookbook_query_params]
    end
  end

  describe "handle_query_params" do
    setup do
      socket = QueryParams.init(@socket)
      %{socket: socket}
    end

    test "foo" do
      socket = QueryParams.init(@socket)

      QueryParams.handle_params(%{}, "http://localhost:4000/foos/1/bars/42?foo=bar", socket)
    end

    test "updates values key on private data", %{socket: socket} do
      socket = QueryParams.track(socket, :foo, type: :integer)
      socket = QueryParams.handle_query_params(socket, %{"foo" => "123"})
      assert %{foo: 123} = socket.private[:hookbook_query_params].values
    end

    test "updates previous_values key on private data for values that changed", %{socket: socket} do
      socket = QueryParams.track(socket, :foo, type: :integer)
      socket = QueryParams.handle_query_params(socket, %{"foo" => "123"})
      assert %{foo: [from: nil, to: 123]} = QueryParams.changes(socket)
    end

    test "does not update previous_values key on private data for values that did not change", %{
      socket: socket
    } do
      socket =
        socket
        |> QueryParams.track(:foo, type: :string)
        |> QueryParams.handle_query_params(%{"foo" => "bar"})
        |> QueryParams.handle_query_params(%{"foo" => "bar"})

      refute socket
             |> QueryParams.changes()
             |> Enum.any?()
    end
  end

  describe "opt: assign" do
    setup do
      socket = QueryParams.init(@socket)
      %{socket: socket}
    end

    test "if true, tracks query param with its respective key on the socket assigns", %{
      socket: socket
    } do
      socket = QueryParams.track(socket, :foo, type: :string, assign: true)
      socket = QueryParams.handle_query_params(socket, %{"foo" => "bar"})
      assert %{foo: "bar"} = socket.assigns
    end

    test "if an atom, tracks query param with that key on the socket assigns", %{socket: socket} do
      socket = QueryParams.track(socket, :foo, type: :string, assign: :bar)
      socket = QueryParams.handle_query_params(socket, %{"foo" => "bar"})
      assert %{bar: "bar"} = socket.assigns
    end

    test "if false, does not track query param on the socket assigns", %{socket: socket} do
      socket = QueryParams.track(socket, :foo, type: :string, assign: false)
      socket = QueryParams.handle_query_params(socket, %{"foo" => "bar"})
      refute Map.has_key?(socket.assigns, :foo)
    end

    test "if nil, does not track query param on the socket assigns", %{socket: socket} do
      socket = QueryParams.track(socket, :foo, type: :string, assign: nil)
      socket = QueryParams.handle_query_params(socket, %{"foo" => "bar"})
      refute Map.has_key?(socket.assigns, :foo)
    end

    test "if unset, does not track query param on the socket assigns", %{socket: socket} do
      socket = QueryParams.track(socket, :foo, type: :string)
      socket = QueryParams.handle_query_params(socket, %{"foo" => "bar"})
      refute Map.has_key?(socket.assigns, :foo)
    end
  end

  describe "changes" do
    setup do
      socket = QueryParams.init(@socket)
      %{socket: socket}
    end

    test "returns changes from private data", %{socket: socket} do
      socket = QueryParams.track(socket, :foo, type: :string)
      socket = QueryParams.handle_query_params(socket, %{"foo" => "bar"})
      assert %{foo: [from: nil, to: "bar"]} = QueryParams.changes(socket)
    end
  end

  describe "values" do
    setup do
      socket = QueryParams.init(@socket)
      %{socket: socket}
    end

    test "returns values from private data", %{socket: socket} do
      socket = QueryParams.track(socket, :foo, type: :string)
      socket = QueryParams.handle_query_params(socket, %{"foo" => "bar"})
      assert %{foo: "bar"} = QueryParams.values(socket)
    end
  end

  describe "decode_param" do
    test "decodes strings" do
      assert "foo" == QueryParams.decode_param("foo", :string)
    end

    test "decodes integers" do
      assert 1 == QueryParams.decode_param("1", :integer)
    end

    test "decodes floats" do
      assert 1.0 == QueryParams.decode_param("1.0", :float)
    end

    test "decodes booleans" do
      assert true == QueryParams.decode_param("true", :boolean)
      assert false == QueryParams.decode_param("false", :boolean)
    end

    test "decodes sorts" do
      assert {:asc, :name} == QueryParams.decode_param("asc:name", :sort)
      assert {:desc, :name} == QueryParams.decode_param("desc:name", :sort)
    end
  end
end
