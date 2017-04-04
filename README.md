# Coney

[![Hex Version](http://img.shields.io/hexpm/v/coney.svg)](https://hex.pm/packages/coney)
[![Build Status](https://travis-ci.org/llxff/coney.svg?branch=master)](https://travis-ci.org/llxff/coney)


Simple consumer server for the RabbitMQ.

## Usage

Add Coney as a dependency in your `mix.exs` file.

```elixir
def deps do
  [{:coney, "~> 0.1.0"}]
end
```

After you are done, run `mix deps.get` in your shell to fetch and compile Coney.

### Setup a consumer server

```elixir
# config/config.exs

config :coney, Coney.AMQPConnection, [
  adapter: Coney.RabbitConnection,
  settings: %{
    url: "amqp://guest:guest@localhost",
    timeout: 1000
  }
]

# config/test.exs

config :coney, Coney.AMQPConnection, adapter: Coney.Test.FakeConnection, settings: %{}

# lib/my_application.ex

children = [
  # ...
  supervisor(Coney.ApplicationSupervisor, [[MyApplication.MyConsumer]])
]

# web/consumers/my_consumer.ex

defmodule MyApplication.MyConsumer do
  def connection do
    %{
      prefetch_count: 10,
      subscribe:      {:fanout, "my_exchange", "my_queue"}
    }
  end

  def parse(payload) do
    String.to_integer(payload)
  end

  def process(number) do
    if number <= 10 do
      {:ok, "Work done"}
    else
      {:error, "Number should be less than 10"}
    end
  end
  
  def error_happen(exception, payload) do
    IO.inspect System.stacktrace()
    IO.puts "Exception raised with #{ payload }"
  end
end
```

### .process return format

1. `{:ok, any}` - message will be marked as performed.
1. `{:error, reason}` - message will be returned to queue once.
1. `{:reply, any}` - response will be published to reply exchange.

### Reply description

To use `{:reply, response}` you should add response exchange in `connection`:

```elixir
# web/consumers/my_consumer.ex

def connection do
  %{
    # ...
    respond_to: {:fanout, "response_exchange"}
  }
end
```

Response will be serialized to JSON and publish to `"response_exchange"` exchange.

### Notice

Exchange with routing key and additional params for exchange/queue currently is not supported.
