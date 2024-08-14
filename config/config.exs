import Config

config :coney,
  pool_size: 1,
  auto_start: true,
  settings: %{
    url: "amqp://guest:guest@localhost",
    timeout: 1000
  },
  workers: [
    FakeConsumer
  ],
  topology: %{
    exchanges: [{:topic, "exchange", durable: false}],
    queues: %{
      "queue" => %{
        options: [
          durable: false
        ],
        bindings: [
          [exchange: "exchange", options: [routing_key: "queue"]]
        ]
      }
    }
  }

config :logger, level: :info

import_config "#{config_env()}.exs"
