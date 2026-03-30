import Config

config :boilerworks, Boilerworks.Repo,
  url:
    System.get_env("DATABASE_URL") ||
      "ecto://boilerworks:boilerworks@localhost:5445/boilerworks_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :boilerworks, BoilerworksWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base:
    System.get_env("SECRET_KEY_BASE") ||
      "dev-only-secret-key-base-that-is-at-least-64-bytes-long-for-phoenix-sessions-ok",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:boilerworks, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:boilerworks, ~w(--watch)]}
  ]

config :boilerworks, BoilerworksWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/boilerworks_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

config :boilerworks, dev_routes: true

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime
