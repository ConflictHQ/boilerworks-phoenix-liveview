defmodule BoilerworksWeb.HealthController do
  use BoilerworksWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "ok", timestamp: DateTime.utc_now()})
  end
end
