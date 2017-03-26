defmodule Coney.ConsumerConnection do
  defstruct subscribe_channel: nil,
            publish_channel: nil

  def build(subscribe_channel, publish_channel) do
    %Coney.ConsumerConnection{subscribe_channel: subscribe_channel, publish_channel: publish_channel}
  end
end
