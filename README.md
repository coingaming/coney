# Coney

[![Hex Version](http://img.shields.io/hexpm/v/coney.svg)](https://hex.pm/packages/coney)
[![Build Status](https://travis-ci.org/llxff/coney.svg?branch=master)](https://travis-ci.org/llxff/coney)


Simple consumer server for the RabbitMQ.

## Usage

Add Coney as a dependency in your `mix.exs` file.

```elixir
def deps do
  [{:coney, "~> 0.4"}]
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

# or
children = [
  # ...
  supervisor(Coney.ApplicationSupervisor, [[
    %{
      connection: %{
        prefetch_count: 10,
        exchange:       {:direct, "my_exchange", durable: true},
        queue:          {"my_queue", durable: true},
        binding:        [routing_key: "routnig_key"]
      },
      worker: MyApplication.MyConsumer
    }
  ]])
]

# web/consumers/my_consumer.ex

defmodule MyApplication.MyConsumer do
  def connection do
    %{
      prefetch_count: 10,
      exchange:       {:direct, "my_exchange", durable: true},
      queue:          {"my_queue", durable: true},
      binding:        [routing_key: "routnig_key"]
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
  
  def error_happened(exception, payload) do
    IO.inspect System.stacktrace()
    IO.puts "Exception raised with #{ payload }"
  end
end
```


### .process return format

1. `{:ok, any}` - message will be marked as performed.
1. `{:error, reason}` - message will be returned to queue once.
1. `{:reject, reason}` - message will be rejected.
1. `{:reply, any}` - response will be published to reply exchange.
1. `{:redeliver, any}` - response will be returned to queue.

### Reply description

To use `{:reply, response}` you should add response exchange in `connection`:

```elixir
# web/consumers/my_consumer.ex

def connection do
  %{
    # ...
    respond_to: {:fanout, "response_exchange", durable: true}
  }
end
```

Response will be serialized to JSON and publish to `"response_exchange"` exchange.

### Publish message

```elixir
Coney.ConnectionServer.publish("exchange", "message")

# or

Coney.ConnectionServer.publish("exchange", "routing_key", "message")
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/llxff/coney.

## License

The library is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
