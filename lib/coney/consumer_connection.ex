defmodule Coney.ConsumerConnection do
  defstruct subscribe_channel: nil,
            publish_channel: nil,
            connection_pid: nil

  def build(connection_pid, subscribe_channel, publish_channel) do
    %__MODULE__{
      subscribe_channel: subscribe_channel,
      publish_channel: publish_channel,
      connection_pid: connection_pid
    }
  end
end
