import Config

config :coney,
  adapter: Coney.RabbitConnection,
  pool_size: 1,
  auto_start: true,
  settings: %{
    url: "amqp://guest:guest@localhost",
    timeout: 1000
  },
  workers: []

config :logger, level: :info

import_config "#{config_env()}.exs"
