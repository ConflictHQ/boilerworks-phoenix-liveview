defmodule Boilerworks.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BoilerworksWeb.Telemetry,
      Boilerworks.Repo,
      {DNSCluster, query: Application.get_env(:boilerworks, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Boilerworks.PubSub},
      {Oban, Application.fetch_env!(:boilerworks, Oban)},
      BoilerworksWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Boilerworks.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    BoilerworksWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
