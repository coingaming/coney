use Mix.Config

config :coney, Coney.AMQPConnection, adapter: Coney.FakeConnection, settings: %{}
