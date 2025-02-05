defmodule Testbed.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TestbedWeb.Telemetry,
      Testbed.Repo,
      {DNSCluster, query: Application.get_env(:testbed, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Testbed.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Testbed.Finch},
      # Start a worker by calling: Testbed.Worker.start_link(arg)
      # {Testbed.Worker, arg},
      # Start to serve requests, typically the last entry
      TestbedWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Testbed.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TestbedWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
