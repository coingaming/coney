defmodule Coney.ExecutionTask do
  defstruct consumer: nil,
            connection: nil,
            payload: nil,
            tag: nil,
            redelivered: false

  def build(consumer, connection, payload, tag, redelivered) do
    %__MODULE__{consumer: consumer, connection: connection, payload: payload, tag: tag, redelivered: redelivered}
  end
end
