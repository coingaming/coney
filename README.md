# Coney

[![Hex.pm Version](https://img.shields.io/hexpm/v/coney)](https://hex.pm/packages/coney)
![Build Status](https://github.com/coingaming/coney/actions/workflows/ci.yaml/badge.svg)

Consumer server for RabbitMQ with message publishing functionality.

## Table of Contents

- [Coney](#Coney)
  - [Table of Contents](#Table-of-Contents)
  - [Installation](#Installation)
  - [Setup a consumer server](#Setup-a-consumer-server)
  - [Configure consumers](#Configure-consumers)
    - [Rescuing exceptions](#Rescuing-exceptions)
      - [error_happened/3](#errorhappened3)
      - [error_happened/4](#errorhappened4)
    - [.process/2 and .error_happened return format](#process2-and-errorhappened-return-format)
    - [Reply description](#Reply-description)
    - [The default exchange](#The-default-exchange)
  - [Publish message](#Publish-message)
  - [Publish message asynchronously](#Publish-message-asynchronously)
  - [Checking connections](#Checking-connections)
  - [Contributing](#Contributing)
  - [License](#License)

## Installation

Add Coney as a dependency in your `mix.exs` file.

```elixir
def deps do
  [{:coney, "~> 3.0"}]
end
```

After you are done, run `mix deps.get` in your shell to fetch and compile Coney.

## Setup a consumer server

Default config:

```elixir
# config/config.exs
config :coney,
  auto_start: true,
  settings: %{
    url: "amqp://guest:guest@localhost", # or ["amqp://guest:guest@localhost", "amqp://guest:guest@other_host"]
    timeout: 1000
  }
```

If you need to create exchanges or queues before starting the consumer, you can define your RabbitMQ topology as follows:
```elixir
  config :coney,
    topology: %{
      exchanges: [{:topic, "my_exchange", durable: true}],
      queues: %{
        "my_queue" => %{
          options: [
            durable: true,
            arguments: [
              {"x-dead-letter-exchange", :longstr, "dlx_exchange"},
              {"x-message-ttl", :signedint, 60000}
            ]
          ],
          bindings: [
            [exchange: "my_exchange", options: [routing_key: "my_queue"]]
          ]
        }
      }
    }
```

Also, you can create a confuguration module (if you want to retreive settings from Consul or something else):

```elixir
# config/config.exs
config :coney,
  auto_start: true,
  settings: RabbitConfig,
  topology: RabbitConfig
```

```elixir
defmodule RabbitConfig do
  def settings do
    %{
      url: "amqp://guest:guest@localhost",
      timeout: 1000
    }
  end

  def topology do
    %{
      exchanges: [{:topic, "my_exchange", durable: true}],
      queues: %{
        "my_queue" => %{
          options: [
            durable: true,
            arguments: [
              {"x-dead-letter-exchange", :longstr, "exchange"},
              {"x-message-ttl", :signedint, 60000}
            ]
          ],
          bindings: [
            [exchange: "my_exchange", options: [routing_key: "my_queue"]]
          ]
        }
      }
    }
  end
end
```

If you don't want to automatically start Coney and want to control it's start, you can set `auto_start` to `false` and add Coney supervisor into yours:


```elixir
# config/config.exs
config :coney, auto_start: false
```

```elixir

defmodule YourApplication do
  use Application

  def start(_type, _args) do
    Supervisor.start_link([Coney.ApplicationSupervisor], [strategy: :one_for_one])
  end
end
```

If you want to disable Coney altogether (useful for testing config) set `enabled: false`
```elixir
# config/config.exs
config :coney, enabled: false, settings: %{}, topology: %{}
```

## Configure consumers

```elixir
# config/queues.exs

config :coney,
  workers: [
    MyApplication.MyConsumer
  ]
# also you can define mapping like this and skip it in consumer module:
  workers: [
    %{
      connection: %{
        prefetch_count: 10,
        queue: "my_queue"
      },
      worker: MyApplication.MyConsumer
    }
  ]
```

```elixir
# web/consumers/my_consumer.ex

defmodule MyApplication.MyConsumer do
  @behaviour Coney.Consumer

  def connection do
    %{
      prefetch_count: 10,
      queue: "my_queue",
      consumer_tag: "MyApp - MyConsumer" # optional
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

To use the default exchange you may declare exchange as `:default`:

```elixir
%{
    exchanges: [:default],
}
```
The following format is also acceptable:

```elixir
%{
  exchanges: [{:direct, ""}]
}
```

Or you can just skip it in the `exchanges` settings and setup the queue in the consumer's settings:

```elixir

%{
  prefetch_count: 10,
  queue: "my_queue"
}

```

## Publish message

```elixir
Coney.publish("exchange", "message")

# or

Coney.publish("exchange", "routing_key", "message")
```

## Publish message asynchronously

```elixir
Coney.publish_async("exchange", "message")

# or

Coney.publish_async("exchange", "routing_key", "message")
```

## Checking connections

You can use`Coney.status/0` if you need to get information about RabbitMQ connections:

```
iex> Coney.status()
[{#PID<0.972.0>, :connected}]
```

Result is a list of tuples, where first element in tuple is a pid of running connection server and second element describes connection status.

Connection status can be:

- `:pending` - when coney just started
- `:connected` - when RabbitMQ connection has been established and all consumers have been started
- `:disconnected` - when coney lost connection to RabbitMQ

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/coingaming/coney.

### Running test suite locally
1. Start the RabbitMQ instance via `docker compose up`.
2. Run `mix test`.

## Architecture
```mermaid
  graph TD;
      A[ApplicationSupervisor - Supervisor] --> B[ConsumerSupervisor - Supervisor];
      A --> C[ConnectionServer - GenServer];
      B -- supervises many --> D[ConsumerServer - GenServer];
      D -- monitors --> E[ConsumerExecutor];
      E -- sends messages to --> C;
      D -- opens AMQP conns via --> C;
```

## License

The library is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
