defmodule RabbitConnectionTest do
  use ExUnit.Case, async: true

  alias AMQP.{Connection, Channel, Basic, Queue}
  alias Coney.RabbitConnection

  describe "RabbitConnection.subscribe/3" do
    setup do
      {:ok, conn} = Connection.open()
      {:ok, chan} = Channel.open(conn)

      on_exit(fn ->
        Channel.close(chan)
        Connection.close(conn)
      end)

      Queue.declare(chan, "generic_queue", [])

      %{chan: chan, conn: conn}
    end

    test "declares direct exchange", %{conn: conn} do
      topology = %{exchanges: [{:direct, "direct_exchange"}], queues: []}

      assert :ok = RabbitConnection.init_topology(conn, topology)
    end

    test "declares fanout exchange", %{conn: conn} do
      topology = %{exchanges: [{:fanout, "fanout_exchange"}], queues: []}

      assert :ok = RabbitConnection.init_topology(conn, topology)
    end

    test "declares topic exchange", %{conn: conn} do
      topology = %{exchanges: [{:topic, "topic_exchange"}], queues: []}

      assert :ok = RabbitConnection.init_topology(conn, topology)
    end

    test "declares queue with default exchange binding", %{conn: conn, chan: chan} do
      queue = {"queue", %{options: [], bindings: [[exchange: "test_exchange"]]}}
      topology = %{exchanges: [{:direct, "test_exchange"}], queues: [queue]}

      assert :ok = RabbitConnection.init_topology(conn, topology)
      assert {:ok, _consumer} = Basic.consume(chan, "queue", nil)
    end

    test "declares queue with default exchange with :default option", %{conn: conn, chan: chan} do
      queue = {"queue", %{options: [], bindings: [[exchange: :default]]}}
      topology = %{exchanges: [], queues: [queue]}

      assert :ok = RabbitConnection.init_topology(conn, topology)
      assert {:ok, _consumer} = Basic.consume(chan, "queue", nil)
    end

    test "declares queue with arguments and binds to exchange with routing key", %{
      conn: conn,
      chan: chan
    } do
      queue =
        {"dlx_queue",
         %{
           options: [arguments: [{"x-dead-letter-exchange", :longstr, "dlx_exchange"}]],
           bindings: [[exchange: "test_exchange", options: [routing_key: "test.route"]]]
         }}

      topology = %{
        exchanges: [{:topic, "dlx_exchange"}, {:direct, "test_exchange"}],
        queues: [queue]
      }

      assert :ok = RabbitConnection.init_topology(conn, topology)
      assert {:ok, _consumer} = Basic.consume(chan, "dlx_queue", nil)
    end

    test "subscribes to a queue", %{chan: chan} do
      consumer = %{
        connection: %{
          prefetch_count: 10,
          queue: "generic_queue"
        }
      }

      assert {:ok, _} = RabbitConnection.subscribe(chan, nil, consumer)
    end
  end
end
