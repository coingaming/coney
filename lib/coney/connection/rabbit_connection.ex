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
    %{prefetch_count: prefetch_count, subscribe: subscribe} = consumer.connection
    {exchange_type, exchange_name, queue} = subscribe

    Basic.qos(chan, prefetch_count: prefetch_count)
    Queue.declare(chan, queue, durable: true)

    Exchange.declare(chan, exchange_name, exchange_type, durable: true)

    Queue.bind(chan, queue, exchange_name)

    {:ok, _consumer_tag} = Basic.consume(chan, queue, consumer_pid)
  end

  def respond_to(chan, {exchange_type, exchange_name}) do
    Exchange.declare(chan, exchange_name, exchange_type, durable: true)
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
