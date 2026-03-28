defmodule Boilerworks.Repo do
  use Ecto.Repo,
    otp_app: :boilerworks,
    adapter: Ecto.Adapters.Postgres
end
