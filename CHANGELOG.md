## [3.0.0]

### Changes

- Introduce RabbitMQ `topology` configuration and setup. Coney now starts up in two phases, first it sets up the topology (queues/exchanges) and then starts consuming from the queues. This allows more complex RabbitMQ setups like retry queues, etc.
- Remove pooling for clusters as this should be handled on cluster side instead.

### Enhancements

- `auto_start` option allow you choose how you want to start Coney. Use `false` value if you want to add `Coney.ApplicationSupervisor` to your supervisor. `true` (default value) means that Coney will run on application start.
- Settings module. You can speficfy a module name under `coney.settings` section and define `settings/0` function, which should return connection configuration.

## [2.2.1]

### Bug fixes

- Fixed bug when connection server's pid remained in the list of connections after death

## [2.2.0]

### Enhancements

- New Coney module with `publish/2`, `publish/3`, `status/0` methods

## [2.1.1]

### Bug fixes

- Fixed bug with logging of consumer start if worker is defined with map

## [2.1.0]

### Enhancements

- Error logs for connection errors
- Error log for unhandled exceptions if `error_handler` is missing
- Debug log after connection was established
- Debug log after consumer was started
- `error_happened/4` callback added

## [2.0.2]

### Enhancements

- Added `:default` option for `connection.exchange`

## [2.0.0]

### Enhancements

- Channel per each publish message.

### Changes

- Change value of `respond_to` field in connection specification to string with exchange name
- No need to add Coney to your application supervisor tree
- Consumers should be described in `worker` config parameter

## [1.0.0]

### Enhancements

- `amqp` updated to version 1.0
- `poison` removed from dependencies
- Added `Coney.Consumer` behaviour
- Added option `pool_size` - number of RabbitMQ connections.

### Changes
- Changed format of consumer `process/2` and `error_happened/3` functions
- `error_happened/3` marked as optional
- `Coney.AMQPConnection` removed from configs
- Logging removed

## [0.4.3]

### Enhancements

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

### Enhancements

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
### Bug fixes

- Fix warnings about undefined behaviour function publish/2, publish/3
