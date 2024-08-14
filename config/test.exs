import Config

config :coney,
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
  },
  pool_size: 1,
  auto_start: true,
  settings: %{
    url: "amqp://guest:guest@localhost:5672",
    timeout: 1000
  },
  workers: [
    FakeConsumer
  ]
