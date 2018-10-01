use Mix.Config

config :coney,
  adapter: Coney.RabbitConnection,
  pool_size: 1,
  settings: %{
    url: "amqp://guest:guest@localhost",
    timeout: 1000
  },
  workers: []

import_config "#{Mix.env()}.exs"
