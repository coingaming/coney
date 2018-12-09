# Coney

[![Hex Version](http://img.shields.io/hexpm/v/coney.svg)](https://hex.pm/packages/coney)
[![Build Status](https://travis-ci.org/llxff/coney.svg?branch=master)](https://travis-ci.org/llxff/coney)

Consumer server for RabbitMQ with message publishing functionality.

## Table of Contents

- [Installation](#installation)
- [Setup a consumer server](#setup-a-consumer-server)
  - [Rescuing exceptions](#rescuing-exceptions)
  - [.process/2 and .error_happened return format](#process2-and-error_happened-return-format)
  - [Reply description](#reply-description)
  - [The default exchange](#the-default-exchange)
- [Publish message](#publish-message)
- [Contributing](#contributing)
- [License](#license)

## Installation

Add Coney as a dependency in your `mix.exs` file.

```elixir
def deps do
  [{:coney, "~> 2.0"}]
end
```

After you are done, run `mix deps.get` in your shell to fetch and compile Coney.

## Setup a consumer server

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

  # Be careful here, if call of `error_happened` will raise an exception, 
  # message will be not handled properly and may be left unacked in a queue
  def error_happened(exception, payload, _meta) do
    IO.puts "Exception raised with #{ payload }"
    :redeliver
  end
end
```

### Rescuing exceptions

If exception was happened during calls of `parse` or `process` functions, by default Coney will reject this message. If you want to add additional functionality in order to handle exception in a special manner, you can implement one of `error_happened/3` or `error_happened/4` callbacks. But be careful, if call of `error_happened` will raise an exception, message will be not handled properly and may be left unacked in a queue.

#### error_happened/3

This callback receives `exception`, original `payload` and `meta` as parameters. Response format is the same as in [process callback](#process2-and-error_happened-return-format).

#### error_happened/4

This callback receives `exception`, `stacktrace`, original `payload` and `meta` as parameters. Response format is the same as in [process callback](#process2-and-error_happened-return-format).

### .process/2 and .error_happened return format

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

### The default exchange

To use the default exchange you should set `connection.exchange` to `:default` parameter:

```elixir
# web/consumers/my_consumer.ex

def connection do
  %{
    # ...
    exchange: :default
  }
end
```
The following format is also acceptable:

```elixir
def connection do
  %{
    # ...
    exchange: {:direct, ""}
  }
end
```

## Publish message

```elixir
Coney.ConnectionServer.publish("exchange", "message")

# or

Coney.ConnectionServer.publish("exchange", "routing_key", "message")
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/llxff/coney.

## License

The library is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
