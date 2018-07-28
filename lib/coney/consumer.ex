defmodule Coney.Consumer do
  @callback connection() :: map()
  @callback parse(message :: binary(), meta :: map()) :: any
  @callback process(payload :: any, meta :: map()) ::
              :ok | :reject | :redeliver | {:reply, binary()}
  @callback error_happend(exception :: struct(), message :: binary(), meta :: map()) ::
              :ok | :reject | :redeliver | {:reply, binary()}

  @optional_callbacks connection: 0, error_happend: 3
end
