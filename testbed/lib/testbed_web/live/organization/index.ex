defmodule TestbedWeb.Live.Organization.Index do
  use TestbedWeb, :live_view
  alias Testbed.Repo
  alias Testbed.Organizations.Organization
  alias Testbed.Organizations
  alias Hookbook.QueryParams

  on_mount {QueryParams, [:page, type: :integer, default: 1]}
  on_mount {QueryParams, [:search, type: :string]}

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

    socket
    |> assign(changes: changes)
    |> then(&{:noreply, &1})
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Organizations {@query_params.page}
      </.header>
      {inspect(@changes)}

      <.button phx-click="seed_organizations">Seed Organizations</.button>

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
end
