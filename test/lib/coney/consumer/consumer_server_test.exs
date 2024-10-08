defmodule ConsumerServerTest do
  use ExUnit.Case, async: true

  alias Coney.ConsumerServer

  setup do
    ref = Coney.ConnectionServer.subscribe(Coney.FakeConsumer)

    [
      args: [Coney.FakeConsumer],
      state: %{consumer: Coney.FakeConsumer, tasks: %{}, chan: ref}
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

  describe "handle_info/2" do
    setup do
      %{state: %{consumer: Coney.FakeConsumer, tasks: Map.new(), chan: :erlang.make_ref()}}
    end

    test "demonitors a task once it completes successfully", %{state: state} do
      task_ref = :erlang.make_ref()
      state = put_in(state, [:tasks, task_ref], 1)

      refute state[:tasks] |> Map.equal?(Map.new())

      down_msg = {:DOWN, task_ref, :dont_care, :dont_care, :normal}

      assert {:noreply, new_state} = ConsumerServer.handle_info(down_msg, state)
      assert new_state[:tasks] |> Map.equal?(Map.new())
    end

    test "demonitors a task and rejects message if it terminates abruptly", %{state: state} do
      task_ref = :erlang.make_ref()

      state = put_in(state, [:tasks, task_ref], 1)

      down_msg = {:DOWN, task_ref, :dont_care, :dont_care, :error}

      assert {:noreply, new_state} = ConsumerServer.handle_info(down_msg, state)

      assert new_state[:tasks] |> Map.equal?(Map.new())
    end
  end
end
