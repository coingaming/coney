defmodule Coney.ConnectionServerTest do
  use ExUnit.Case

  alias Coney.ConnectionServer
  alias Coney.RabbitConnection

  setup do
    settings = %{url: "amqp://guest:guest@localhost:5672", timeout: 1_000}
    topology = Map.new()
    %{init_args: %{adapter: RabbitConnection, settings: settings, topology: topology}}
  end

  describe "init/1" do
    test "starts with default settings", %{init_args: init_args} do
      %{settings: settings, adapter: adapter, topology: topology} = init_args

      assert {:ok, state, {:continue, nil}} = ConnectionServer.init([adapter, settings, topology])

      assert state.channels |> Map.equal?(Map.new())
      assert state.adapter == adapter
      assert state.settings == settings
      assert state.topology == topology
    end

    test "registers itself in the connection registry", %{init_args: init_args} do
      %{settings: settings, adapter: adapter, topology: topology} = init_args

      assert {:ok, _state, {:continue, nil}} = ConnectionServer.init([adapter, settings, topology])

      status = Coney.HealthCheck.ConnectionRegistry.status() |> Map.new()

      assert Map.get(status, self(), :connected)
    end
  end

  describe "handle_continue/2" do
    test "sets the connection in the state", %{init_args: init_args} do
      %{settings: settings, adapter: adapter, topology: topology} = init_args
      assert {:ok, state, {:continue, nil}} = ConnectionServer.init([adapter, settings, topology])

      assert is_nil(state.amqp_conn)

      assert {:noreply, new_state} = ConnectionServer.handle_continue(nil, state)

      refute is_nil(new_state.amqp_conn)
    end
  end

  describe "handle_info/2" do
    test "reconnects channels when receives a connection lost message", %{init_args: init_args} do
      %{settings: settings, adapter: adapter, topology: topology} = init_args
      # Init
      assert {:ok, state, {:continue, nil}} = ConnectionServer.init([adapter, settings, topology])

      # Open connection
      assert {:noreply, state} = ConnectionServer.handle_continue(nil, state)

      # Subscribe a channel
      assert {:reply, channel_ref, connected_state} =
               ConnectionServer.handle_call(
                 {:subscribe, Coney.FakeConsumer},
                 {self(), :erlang.make_ref()},
                 state
               )

      channel_info = Map.get(connected_state.channels, channel_ref)

      # Connection lost
      down_msg = {:DOWN, :erlang.make_ref(), :process, self(), :connection_lost}

      assert {:noreply, reconnect_state} = ConnectionServer.handle_info(down_msg, connected_state)

      new_channel_info = Map.get(reconnect_state.channels, channel_ref)

      {_pid, consumer, old_channel} = channel_info
      {_other_pid, ^consumer, new_channel} = new_channel_info

      refute old_channel == new_channel
    end
  end

  describe "handle_call/3" do
    test "subscribes a consumer and returns a channel reference", %{init_args: init_args} do
      %{settings: settings, adapter: adapter, topology: topology} = init_args
      # Init
      assert {:ok, state, {:continue, nil}} = ConnectionServer.init([adapter, settings, topology])

      # Open connection
      assert {:noreply, state} = ConnectionServer.handle_continue(nil, state)

      # Subscribe a channel
      assert {:reply, channel_ref, new_state} =
               ConnectionServer.handle_call(
                 {:subscribe, Coney.FakeConsumer},
                 {self(), :erlang.make_ref()},
                 state
               )

      assert is_reference(channel_ref)

      pid = self()

      assert {^pid, Coney.FakeConsumer, _} = Map.get(new_state.channels, channel_ref)
    end
  end
end
