use Mix.Config

config :coney, Coney.AMQPConnection, adapter: Coney.FakeAMQPConnection, settings: %{}
