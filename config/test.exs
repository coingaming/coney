import Config

config :coney,
  adapter: Coney.RabbitConnection,
  pool_size: 1,
  auto_start: true,
  settings: %{
    url: "amqp://guest:guest@localhost:5672",
    timeout: 1000
  },
  workers: []
