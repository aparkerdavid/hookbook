defmodule Hookbook.QueryParamsTest do
  use ExUnit.Case
  alias Hookbook.QueryParams
  alias Phoenix.LiveView.Socket
  alias Phoenix.LiveView

  @socket %Socket{private: %{lifecycle: %{handle_params: []}}, router: true}

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
end
