defmodule Coney.ConnectionServerTest do
  use ExUnit.Case

  alias Coney.ConnectionServer
  alias Coney.RabbitConnection

  describe "init/1" do
    setup do
      settings = %{url: "https://example.com", timeout: 1_000}
      topology = Map.new()
      %{init_args: %{adapter: RabbitConnection, settings: settings, topology: topology}}
    end

    test "starts with default settings", %{init_args: init_args} do
      %{settings: settings, adapter: adapter, topology: topology} = init_args

      assert {:ok, state} = ConnectionServer.init([adapter, settings, topology])

      assert state.channels |> Map.equal?(Map.new())
      assert state.adapter == adapter
      assert state.settings == settings
      assert state.topology == topology
    end

    test "sends itself an after_init message", %{init_args: init_args} do
      %{settings: settings, adapter: adapter, topology: topology} = init_args

      assert {:ok, _state} = ConnectionServer.init([adapter, settings, topology])

      assert_receive :after_init
    end

    test "registers itself in the connection registry", %{init_args: init_args} do
      %{settings: settings, adapter: adapter, topology: topology} = init_args

      assert {:ok, _state} = ConnectionServer.init([adapter, settings, topology])

      status = Coney.HealthCheck.ConnectionRegistry.status() |> Map.new()

      assert Map.get(status, self(), :connected)
    end
  end
end
