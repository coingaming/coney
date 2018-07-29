defmodule Coney.ExecutionTask do
  defstruct consumer: nil,
            connection: nil,
            payload: nil,
            tag: nil,
            meta: %{}

  def build(consumer, connection, payload, tag, meta) do
    %__MODULE__{consumer: consumer, connection: connection, payload: payload, tag: tag, meta: meta}
  end
end
