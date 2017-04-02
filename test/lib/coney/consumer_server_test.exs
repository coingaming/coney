defmodule ConsumerServerTest do
  use ExUnit.Case, async: true

  alias Coney.ConsumerServer
  alias Coney.Test.FakeConsumer

  setup do
    [state: [FakeConsumer, :channel]]
  end

  test "initial state", %{state: state} do
    assert {:ok, {FakeConsumer, :channel}} = ConsumerServer.init(state)
  end

  test ":basic_consume_ok", %{state: state} do
    assert {:noreply, ^state} = ConsumerServer.handle_info({:basic_consume_ok, %{consumer_tag: nil}}, state)
  end

  test ":basic_cancel", %{state: state} do
    assert {:stop, :normal, ^state} = ConsumerServer.handle_info({:basic_cancel, %{consumer_tag: nil}}, state)
  end

  test ":basic_cancel_ok", %{state: state} do
    assert {:noreply, ^state} = ConsumerServer.handle_info({:basic_cancel_ok, %{consumer_tag: nil}}, state)
  end

  test ":basic_deliver", %{state: [consumer, channel]} do
    message = {:basic_deliver, :payload, %{delivery_tag: :tag, redelivered: :redelivered}}

    assert {:noreply, {^consumer, ^channel}} = ConsumerServer.handle_info(message, {consumer, channel})
  end
end
