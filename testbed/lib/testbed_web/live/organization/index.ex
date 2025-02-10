defmodule TestbedWeb.Live.Organization.Index do
  use TestbedWeb, :live_view
  alias Testbed.Repo
  alias Testbed.Organizations.Organization
  alias Testbed.Organizations
  use Hookbook.QueryParams

  query_param(:page, type: :integer, default: 1, assign: true)
  query_param(:foo, type: :string, assign: :bar)

  query_param(:count, type: :integer, default: 0, assign: true)

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
  def handle_params(_, _, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Organizations
      </.header>
      <p>
        count: {@count}
      </p>
      <.button phx-click="increment">Increment</.button>
      <.button phx-click="clear">Clear</.button>

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

  def handle_event("increment", _params, socket) do
    socket
    |> QueryParams.merge(%{count: socket.assigns.count + 1})
    |> then(&{:noreply, &1})
  end

  def handle_event("clear", _params, socket) do
    socket
    |> QueryParams.drop([:count])
    |> then(&{:noreply, &1})
  end
end
