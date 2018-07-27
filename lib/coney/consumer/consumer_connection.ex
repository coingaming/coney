defmodule Coney.ConsumerConnection do
  alias Coney.ConsumerConnection

  defstruct subscribe_channel: nil,
            publish_channel: nil

  def build(subscribe_channel, publish_channel) do
    %ConsumerConnection{subscribe_channel: subscribe_channel, publish_channel: publish_channel}
  end
end
