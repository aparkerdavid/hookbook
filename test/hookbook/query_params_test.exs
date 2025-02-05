defmodule Hookbook.QueryParamsTest do
  use ExUnit.Case
  alias Hookbook.QueryParams
  alias Phoenix.LiveView
  alias Phoenix.Component

  # a socket that looks as if it were mounted at the router
  @socket %LiveView.Socket{private: %{lifecycle: %{handle_params: []}}, router: true}

  describe "ensure_init" do
    test "ensures presence of default values in the :hookbook_query_params key of private data" do
      socket = @socket
      refute socket.private[:hookbook_query_params]

      socket = QueryParams.ensure_init(socket)
      assert %{changes: %{}, specs: []} = socket.private[:hookbook_query_params]
    end

    test "ensures presence of query_params key on assigns" do
      socket = @socket
      refute socket.assigns[:query_params]

      socket = QueryParams.ensure_init(socket)
      assert %{} = socket.assigns[:query_params]
    end

    test "does not trample existing data" do
      socket =
        @socket
        |> Map.put(:assigns, %{query_params: %{foo: "bar"}})
        |> LiveView.put_private(:hookbook_query_params, %{
          changes: %{foo: [from: "baz", to: "bar"]},
          specs: [:foo, type: :string]
        })

      socket = QueryParams.ensure_init(socket)

      assert %{changes: %{foo: [from: "baz", to: "bar"]}, specs: [:foo, type: :string]} =
               socket.private[:hookbook_query_params]

      assert %{foo: "bar"} = socket.assigns[:query_params]
    end

    test "adds handle_params callback to clear changes from private data" do
      socket = QueryParams.ensure_init(@socket)

      assert [%{id: QueryParams.ClearChanges}] = socket.private.lifecycle.handle_params
    end

    test "does not try to duplicate ClearChanges handler" do
      socket =
        @socket
        |> QueryParams.ensure_init()
        |> QueryParams.ensure_init()

      assert [%{id: QueryParams.ClearChanges}] = socket.private.lifecycle.handle_params
    end
  end

  describe "assign_spec" do
    test "ensures init" do
      socket = QueryParams.assign_spec(@socket, [:foo, type: :string])
      private = socket.private[:hookbook_query_params]
      assert private.specs
      assert private.changes
    end

    test "adds a spec to the :specs key of private data" do
      socket = QueryParams.assign_spec(@socket, [:foo, type: :string])

      assert %{specs: [[:foo, type: :string]]} = socket.private[:hookbook_query_params]
    end

    test "adds default value to query params" do
      socket =
        @socket
        |> QueryParams.assign_spec([:foo, type: :string, default: "bar"])
        |> QueryParams.assign_spec([:baz, type: :integer])

      assert %{foo: "bar", baz: nil} = socket.assigns[:query_params]
    end

    test "attaches handle_params hook for spec'd param" do
      socket = QueryParams.assign_spec(@socket, [:foo, type: :string])

      assert [%{id: QueryParams.ClearChanges}, %{id: {QueryParams, :foo}}] =
               socket.private.lifecycle.handle_params
    end
  end

  describe "handle_query_params" do
    test "updates query_params key on assigns" do
      socket = QueryParams.assign_spec(@socket, [:foo, type: :integer])
      socket = QueryParams.handle_query_params(socket, [:foo, type: :integer], %{"foo" => "123"})
      assert %{foo: 123} = socket.assigns[:query_params]
    end

    test "updates private data with changes" do
      socket = QueryParams.assign_spec(@socket, [:foo, type: :integer])
      socket = QueryParams.handle_query_params(socket, [:foo, type: :integer], %{"foo" => "123"})
      assert %{foo: [from: nil, to: 123]} = QueryParams.changes(socket)
    end

    test "does not update private data for fields that did not change" do
      socket =
        @socket
        |> QueryParams.assign_spec([:foo, type: :string])
        |> Component.assign(query_params: %{foo: "bar"})
        |> QueryParams.handle_query_params([:foo, type: :string], %{"foo" => "bar"})

      refute socket
             |> QueryParams.changes()
             |> Enum.any?()
    end
  end

  describe "changes" do
    test "returns changes from private data" do
      socket = QueryParams.assign_spec(@socket, [:foo, type: :string])
      socket = QueryParams.handle_query_params(socket, [:foo, type: :string], %{"foo" => "bar"})
      assert %{foo: [from: nil, to: "bar"]} = QueryParams.changes(socket)
    end
  end

  describe "decode_query_param" do
    test "decodes strings" do
      assert "foo" == QueryParams.decode_query_param("foo", :string)
    end

    test "decodes integers" do
      assert 1 == QueryParams.decode_query_param("1", :integer)
    end

    test "decodes floats" do
      assert 1.0 == QueryParams.decode_query_param("1.0", :float)
    end

    test "decodes booleans" do
      assert true == QueryParams.decode_query_param("true", :boolean)
      assert false == QueryParams.decode_query_param("false", :boolean)
    end

    test "decodes sorts" do
      assert {:asc, :name} == QueryParams.decode_query_param("asc:name", :sort)
      assert {:desc, :name} == QueryParams.decode_query_param("desc:name", :sort)
    end
  end
end
