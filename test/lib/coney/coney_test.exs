defmodule Coney.ConeyTest do
  use ExUnit.Case
  use AMQP

  describe "publish/2" do
    test "consumes a message" do
      {:ok, connection} = AMQP.Connection.open(Application.get_env(:coney, :settings)[:url])

      {:ok, channel} = AMQP.Channel.open(connection)

      assert :ok == AMQP.Basic.publish(channel, "exchange", "queue", "message", mandatory: true)

      refute 0 == AMQP.Queue.consumer_count(channel, "queue")
    end
  end
end
