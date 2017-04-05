defmodule Coney.RabbitConnection do
  require Logger

  use AMQP

  @behaviour Coney.AMQPConnection

  def open(settings = %{url: url, timeout: timeout}) do
    case Connection.open(url) do
      {:ok, conn} ->
        Process.link(conn.pid)
        conn
      {:error, _} ->
         Logger.error "Unable to connect to RabbitMQ, trying reconnect..."
        :timer.sleep(timeout)
        open(settings)
    end
  end

  def create_channel(conn) do
    {:ok, chan} = Channel.open(conn)
    chan
  end

  def subscribe(chan, consumer_pid, consumer) do
    connection = consumer.connection

    Basic.qos(chan, prefetch_count: connection.prefetch_count)

    exchange_name = declare_exchange(chan, connection.exchange)
    queue = declare_queue(chan, connection.queue)

    Queue.bind(chan, queue, exchange_name)

    {:ok, _consumer_tag} = Basic.consume(chan, queue, consumer_pid)
  end

  defp declare_exchange(chan, {type, name}) do
    declare_exchange(chan, {type, name, []})
  end

  defp declare_exchange(chan, {type, name, params}) do
    Exchange.declare(chan, name, type, params)
    name
  end

  defp declare_queue(chan, {name}) do
    declare_queue(chan, {name, []})
  end

  defp declare_queue(chan, {name, params}) do
    Queue.declare(chan, name, params)
    name
  end

  def respond_to(chan, exchange) do
    declare_exchange(chan, exchange)
  end

  def publish(chan, exchange_name, routing_key, message) do
    Basic.publish(chan, exchange_name, routing_key, message)
  end

  def confirm(channel, tag) do
    Basic.ack(channel, tag)
  end

  def reject(channel, tag, opts) do
    Basic.reject(channel, tag, opts)
  end
end
