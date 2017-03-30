defmodule Coney.ExecutionTask do
  defstruct consumer: nil,
            connection: nil,
            payload: nil,
            tag: nil,
            redelivered: false

  def build(consumer, connection, payload, tag, redelivered) do
    %Coney.ExecutionTask{consumer: consumer, connection: connection, payload: payload, tag: tag, redelivered: redelivered}
  end
end
