defmodule TestbedWeb.Live.Organization.Index do
  use TestbedWeb, :live_view
  alias Testbed.Repo
  alias Testbed.Organizations.Organization
  alias Testbed.Organizations
  use Hookbook.QueryParams

  query_param(:page, type: :integer, default: 1)
  query_param(:foo, type: :string)

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(
      organizations: Repo.all(Organization),
      changes: %{}
    )
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    changes = QueryParams.changes(socket)
    values = QueryParams.values(socket)

    socket
    |> assign(changes: changes, values: values)
    |> then(&{:noreply, &1})
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Organizations
      </.header>
      <p>
        values: {inspect(@values)}
      </p>
      <p>
        changes: {inspect(@changes)}
      </p>
      <.button phx-click="seed_organizations">Seed Organizations</.button>
      <.link patch={~p"/organizations?foo=Bar"}>Bar</.link>
      <.link patch={~p"/organizations?foo=Baz"}>Baz</.link>
      <.link patch={~p"/organizations?foo=Qux"}>Qux</.link>
      <.link patch={~p"/organizations"}>Nil</.link>
      <div
        :for={organization <- @organizations}
        class="p-4 mb-4 rounded-lg border border-gray-200 shadow-sm"
      >
        <.link
          navigate={~p"/organizations/#{organization.id}"}
          class="text-lg font-semibold hover:text-blue-600"
        >
          {organization.name}
        </.link>
        <p class="mt-2 text-gray-600 italic">
          {organization.description}
        </p>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("seed_organizations", _params, socket) do
    Organizations.seed_organizations()

    socket
    |> assign(:organizations, Repo.all(Organization))
    |> then(&{:noreply, &1})
  end

  def handle_event("click_me", _params, socket) do
    socket
    |> push_patch(to: ~p"/organizations?foo=bar")
    |> then(&{:noreply, &1})
  end
end
