defmodule Coney.RabbitConnection do
  use AMQP

  require Logger

  def open(settings = %{url: url, timeout: timeout}) do
    case connect(url) do
      {:ok, conn} ->
        Logger.debug("#{__MODULE__} (#{inspect(self())}) connected to #{url}")

        Process.monitor(conn.pid)
        conn

      {:error, error} ->
        Logger.error(
          "#{__MODULE__} (#{inspect(self())}) connection to #{url} refused: #{inspect(error)}"
        )

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

    queue = declare_queue(chan, connection.queue)

    exchange_name = declare_exchange(chan, Map.get(connection, :exchange, nil))

    bind_queue(chan, exchange_name, queue, Map.get(connection, :binding, []))

    {:ok, _consumer_tag} = Basic.consume(chan, queue, consumer_pid)
  end

  defp declare_queue(chan, {name}) do
    declare_queue(chan, {name, []})
  end

  defp declare_queue(chan, {name, params}) do
    Queue.declare(chan, name, params)
    name
  end

  defp declare_exchange(chan, {type, name}) do
    declare_exchange(chan, {type, name, []})
  end

  defp declare_exchange(_, {:direct, "", _}), do: :default_exchange
  defp declare_exchange(_, :default), do: :default_exchange

  defp declare_exchange(chan, {type, name, params}) do
    Exchange.declare(chan, name, type, params)
    name
  end

  defp bind_queue(_, :default_exchange, _, _), do: :ok

  defp bind_queue(chan, exchange_name, queue, options) do
    Queue.bind(chan, queue, exchange_name, options)
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
