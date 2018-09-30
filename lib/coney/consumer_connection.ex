defmodule Coney.ConsumerConnection do
  defstruct subscribe_channel: nil,
            connection_server_pid: nil

  def build(connection_server_pid, subscribe_channel) do
    %__MODULE__{
      subscribe_channel: subscribe_channel,
      connection_server_pid: connection_server_pid
    }
  end
end
