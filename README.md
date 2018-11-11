# Coney

[![Hex Version](http://img.shields.io/hexpm/v/coney.svg)](https://hex.pm/packages/coney)
[![Build Status](https://travis-ci.org/llxff/coney.svg?branch=master)](https://travis-ci.org/llxff/coney)

Simple consumer server for the RabbitMQ.

## Usage

Add Coney as a dependency in your `mix.exs` file.

```elixir
def deps do
  [{:coney, "~> 2.0"}]
end
```

After you are done, run `mix deps.get` in your shell to fetch and compile Coney.

### Setup a consumer server

```elixir
# config/config.exs
config :coney,
  adapter: Coney.RabbitConnection,
  pool_size: 1,
  settings: %{
    url: "amqp://guest:guest@localhost", # or ["amqp://guest:guest@localhost", "amqp://guest:guest@other_host"]
    timeout: 1000
  },
  workers: [
    MyApplication.MyConsumer
  ]
# or
  workers: [
    %{
      connection: %{
        prefetch_count: 10,
        exchange:       {:direct, "my_exchange", durable: true},
        queue:          {"my_queue", durable: true},
        binding:        [routing_key: "routing_key"]
      },
      worker: MyApplication.MyConsumer
    }
  ]
```

```elixir
# config/test.exs

config :coney, adapter: Coney.FakeConnection, settings: %{}
```

```elixir
# web/consumers/my_consumer.ex

defmodule MyApplication.MyConsumer do
  @behaviour Coney.Consumer

  def connection do
    %{
      prefetch_count: 10,
      exchange:       {:direct, "my_exchange", durable: true},
      queue:          {"my_queue", durable: true},
      binding:        [routing_key: "routnig_key"]
    }
  end

  def parse(payload, _meta) do
    String.to_integer(payload)
  end

  def process(number, _meta) do
    if number <= 10 do
      :ok
    else
      :reject
    end
  end

  def error_happened(exception, payload, _meta) do
    IO.inspect __STACKTRACE__
    IO.puts "Exception raised with #{ payload }"
    :redeliver
  end
end
```

### .process/2 and .error_happened/3 return format

1. `:ok` - ack message.
1. `:reject` - reject message.
1. `:redeliver` - return message to the queue.
1. `{:reply, binary}` - response will be published to reply exchange.

### Reply description

To use `{:reply, binary}` you should add response exchange in `connection`:

```elixir
# web/consumers/my_consumer.ex

def connection do
  %{
    # ...
    respond_to: "response_exchange"
  }
end
```

Response will be published to `"response_exchange"` exchange.

### Default exchange

To use default exchange setup `connection.exchange` to `:default` parameter:

```elixir
# web/consumers/my_consumer.ex

def connection do
  %{
    # ...
    exchange: :default
  }
end
```

or you can use the following format:

# or

```elixir
def connection do
  %{
    # ...
    exchange: {:direct, ""}
  }
end
```

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
