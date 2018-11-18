## [2.0.2]

### Changes

- Added `:default` option for `connection.exchange`

## [2.0.0]

### Changes

Create new channel per each publish message.

- Change value of `respond_to` field in connection specification to string with exchange name
- No need to add Coney to your application supervisor tree
- Consumers should be described in `worker` config parameter

## [1.0.0]

### Changes

- `amqp` updated to version 1.0
- `poison` removed from dependencies
- Changed format of consumer `process/2` and `error_happened/3` functions
- `error_happened/3` marked as optional
- Added `Coney.Consumer` behaviour
- `Coney.AMQPConnection` removed from configs
- Logging removed
- Added option `pool_size` - number of RabbitMQ connections.

## [0.4.3]

### Changes

- Allow to define several RabbitMQ hosts for connection (will be used random host from list)

  ```elixir
  # config/config.exs

  config :coney, Coney.AMQPConnection, [
    settings: %{
      url: ["amqp://guest:guest@localhost", "amqp://guest:guest@other_host"]
    }
  ]
  ```
## [0.4.2]

### Changes

- `{:reject, reason}` return value:
  Reject message without redelivery.

  ```elixir
  defmodule MyConsumer do
    def connection do
      #...
    end

    def parse(payload) do
      String.to_integer(payload)
    end

    def process(number) do
      if number <= 10 do
        {:ok, "Work done"}
      else
        {:reject, "Number should be less than 10"}
      end
    end
  end
  ```
- Fix warnings about undefined behaviour function publish/2, publish/3
