use Mix.Config

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:consumer, :tag, :redelivered]

config :coney, Coney.AMQPConnection, [
  adapter: Coney.RabbitConnection,
  settings: %{
    url: "amqp://guest:guest@localhost",
    timeout: 1000
  }
]

import_config "#{Mix.env}.exs"
