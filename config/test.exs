use Mix.Config

config :coney, Coney.AMQPConnection, adapter: Coney.Test.FakeConnection, settings: %{}
