import Config

config :boilerworks,
  ecto_repos: [Boilerworks.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

config :boilerworks, BoilerworksWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: BoilerworksWeb.ErrorHTML, json: BoilerworksWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Boilerworks.PubSub,
  live_view: [signing_salt: "boilerworks_lv_salt"]

config :boilerworks, Oban,
  repo: Boilerworks.Repo,
  queues: [default: 10, mailers: 5]

config :esbuild,
  version: "0.17.11",
  boilerworks: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.4.3",
  boilerworks: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
