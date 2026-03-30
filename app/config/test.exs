import Config

config :boilerworks, Boilerworks.Repo,
  url:
    System.get_env("DATABASE_URL") ||
      "ecto://boilerworks:boilerworks@localhost:5446/boilerworks_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :boilerworks, BoilerworksWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base:
    "test-secret-key-base-that-is-at-least-64-bytes-long-for-phoenix-testing-purposes",
  server: false

config :boilerworks, Oban, testing: :inline

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime

config :bcrypt_elixir, :log_rounds, 1
