defmodule Coney.RabbitConnection do
  use AMQP

  def open(settings = %{url: url, timeout: timeout}) do
    case connect(url) do
      {:ok, conn} ->
        Process.link(conn.pid)
        conn

      {:error, _} ->
        :timer.sleep(timeout)
        open(settings)
    end
  end

  defp connect(url) do
    url
    |> choose_server()
    |> Connection.open()
  end

  defp choose_server(url) when is_binary(url), do: url
  defp choose_server(urls) when is_list(urls), do: Enum.random(urls)

  def create_channel(conn) do
    {:ok, chan} = Channel.open(conn)
    chan
  end

  def subscribe(chan, consumer_pid, consumer) do
    connection = consumer.connection

    Basic.qos(chan, prefetch_count: connection.prefetch_count)

    exchange_name = declare_exchange(chan, connection.exchange)
    queue = declare_queue(chan, connection.queue)

    Queue.bind(chan, queue, exchange_name, Map.get(connection, :binding, []))

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

  def publish(conn, exchange_name, routing_key, message) do
    chan = create_channel(conn)

    try do
      Basic.publish(chan, exchange_name, routing_key, message)
    after
      Channel.close(chan)
    end
  end

  def confirm(channel, tag) do
    Basic.ack(channel, tag)
  end

  def reject(channel, tag, opts) do
    Basic.reject(channel, tag, opts)
  end
end
