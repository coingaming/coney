use Mix.Config

config :logger, backends: []

config :coney, Coney.AMQPConnection, adapter: Coney.Test.FakeConnection, settings: %{}
