defmodule ConsumerServerTest do
  use ExUnit.Case, async: true

  alias Coney.ConsumerServer

  setup do
    [
      args: [FakeConsumer],
      state: %{consumer: FakeConsumer, tasks: %{}, chan: :erlang.make_ref()}
    ]
  end

  test "initial state", %{args: args, state: state} do
    assert {:ok, initial_state} = ConsumerServer.init(args)
    assert initial_state.consumer == state.consumer
    assert initial_state.tasks |> Map.equal?(Map.new())
    assert initial_state.chan |> is_reference()
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

    {:noreply, updated_state} = ConsumerServer.handle_info(message, state)

    assert updated_state.consumer == state.consumer
    assert updated_state.chan == state.chan
  end
end
