defmodule Coney.ExecutionTask do
  defstruct consumer: nil,
            settings: %{},
            connection: nil,
            payload: nil,
            tag: nil,
            meta: %{}

  def build(%{worker: consumer, connection: settings}, connection, payload, tag, meta) do
    %__MODULE__{
      consumer: consumer,
      settings: settings,
      connection: connection,
      payload: payload,
      tag: tag,
      meta: meta
    }
  end

  def build(consumer, connection, payload, tag, meta) do
    %__MODULE__{
      consumer: consumer,
      settings: consumer.connection(),
      connection: connection,
      payload: payload,
      tag: tag,
      meta: meta
    }
  end
end
