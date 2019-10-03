defmodule Coney.RabbitConnection do
  use AMQP

  require Logger

  def open(%{url: url, timeout: timeout} = settings) do
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

    {:ok, _consumer_tag} = Basic.consume(chan, connection.queue, consumer_pid)
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

  def init_topology(conn, %{exchanges: exchanges, queues: queues}) do
    channel = create_channel(conn)

    Enum.each(exchanges, &declare_exchange(channel, &1))
    Enum.each(queues, &declare_queue(channel, &1))

    Channel.close(channel)
  end

  defp declare_queue(channel, {name, %{options: opts, bindings: bindings}}) do
    Queue.declare(channel, name, opts)
    Enum.each(bindings, &create_binding(channel, name, &1))

    name
  end

  defp declare_queue(channel, {name, _}) do
    declare_queue(channel, %{name: name, options: [], bindings: []})
  end

  defp create_binding(_channel, _queue, []) do
    :ok
  end

  defp create_binding(channel, queue, binding_opts) do
    exchange = Keyword.get(binding_opts, :exchange, :default)
    opts = Keyword.get(binding_opts, :options, [])
    create_binding(channel, queue, exchange, opts)
  end

  defp create_binding(_channel, _queue, :default, _opts) do
    :ok
  end

  defp create_binding(channel, queue, exchange, opts) do
    Queue.bind(channel, queue, exchange, opts)
  end

  defp declare_exchange(channel, {type, name}) do
    declare_exchange(channel, {type, name, []})
  end

  defp declare_exchange(channel, {type, name, params}) do
    Exchange.declare(channel, name, type, params)
    name
  end
end
