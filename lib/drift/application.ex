defmodule Drift.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DriftWeb.Telemetry,
      Drift.Repo,
      {DNSCluster, query: Application.get_env(:drift, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Drift.PubSub},
      # Start a worker by calling: Drift.Worker.start_link(arg)
      # {Drift.Worker, arg},
      # Start to serve requests, typically the last entry
      DriftWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Drift.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DriftWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
