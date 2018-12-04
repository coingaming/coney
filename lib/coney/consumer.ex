defmodule Coney.Consumer do
  @type stacktrace :: []
  @type error_tuple :: {exception :: struct(), stacktrace}
  @callback connection() :: map()
  @callback parse(message :: binary(), meta :: map()) :: any
  @callback process(payload :: any, meta :: map()) ::
              :ok | :reject | :redeliver | {:reply, binary()}
  @callback error_happend(error :: error_tuple(), message :: binary(), meta :: map()) ::
              :ok | :reject | :redeliver | {:reply, binary()}

  @optional_callbacks connection: 0, error_happend: 3
end
