defmodule RabbitConnectionTest do
  use ExUnit.Case, async: true

  alias AMQP.{Connection, Channel}
  alias Coney.RabbitConnection

  describe "RabbitConnection.subscribe/3" do
    setup do
      {:ok, conn} = Connection.open()
      {:ok, chan} = Channel.open(conn)

      on_exit(fn ->
        Channel.close(chan)
        Connection.close(conn)
      end)

      %{chan: chan}
    end

    test "subscribes to the default exchange using :default option", %{chan: chan} do
      consumer = build_consumer(:default)

      assert {:ok, _} = RabbitConnection.subscribe(chan, nil, consumer)
    end

    test "subscribes to the default exchange using empty string as name", %{chan: chan} do
      consumer = build_consumer({:direct, ""})

      assert {:ok, _} = RabbitConnection.subscribe(chan, nil, consumer)
    end

    test "subscribes to a direct exchange", %{chan: chan} do
      consumer = build_consumer({:direct, rand_name()})

      assert {:ok, _} = RabbitConnection.subscribe(chan, nil, consumer)
    end

    test "subscribes to a fanout exchange", %{chan: chan} do
      consumer = build_consumer({:fanout, rand_name()})

      assert {:ok, _} = RabbitConnection.subscribe(chan, nil, consumer)
    end

    test "subscribes to a topic exchange", %{chan: chan} do
      consumer = build_consumer({:topic, rand_name()})

      assert {:ok, _} = RabbitConnection.subscribe(chan, nil, consumer)
    end

    defp rand_name do
      :crypto.strong_rand_bytes(8) |> Base.encode64()
    end

    defp build_consumer(exchange_opts) do
      %{
        connection: %{
          prefetch_count: 10,
          exchange: exchange_opts,
          queue: {"test_queue"}
        }
      }
    end
  end
end
