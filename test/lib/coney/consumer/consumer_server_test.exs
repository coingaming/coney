defmodule ConsumerServerTest do
  use ExUnit.Case, async: true

  alias Coney.{ConsumerServer, ConsumerConnection}

  setup do
    connection = ConsumerConnection.build(:channel, :channel)

    [
      args: [FakeConsumer, connection],
      state: %{consumer: FakeConsumer, connection: connection}
    ]
  end

  test "initial state", %{args: args, state: state} do
    assert {:ok, ^state} = ConsumerServer.init(args)
  end

  test ":basic_consume_ok", %{state: state} do
    assert {:noreply, ^state} =
             ConsumerServer.handle_info({:basic_consume_ok, %{consumer_tag: nil}}, state)
  end

  test ":basic_cancel", %{state: state} do
    assert {:stop, :normal, ^state} =
             ConsumerServer.handle_info({:basic_cancel, %{consumer_tag: nil}}, state)
  end

  test ":basic_cancel_ok", %{state: state} do
    assert {:noreply, ^state} =
             ConsumerServer.handle_info({:basic_cancel_ok, %{consumer_tag: nil}}, state)
  end

  test ":basic_deliver", %{state: state} do
    message =
      {:basic_deliver, :ok, %{delivery_tag: :tag, redelivered: :redelivered, routing_key: ""}}

    assert {:noreply, ^state} = ConsumerServer.handle_info(message, state)
  end
end
