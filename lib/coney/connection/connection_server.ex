defmodule Coney.ConnectionServer do
  require Logger

  use GenServer

  alias Coney.{ConsumerSupervisor, ConsumerConnection}

  @name __MODULE__

  def start_link(consumers, settings) do
    GenServer.start_link(@name, [consumers, settings], name: @name)
  end

  def init([consumers, settings]) do
    Logger.info "ConnectionServer started"
    rabbitmq_connect(consumers, settings)
  end

  def confirm(channel, tag) do
    GenServer.call(@name, {:confirm, channel, tag})
  end

  def reject(channel, tag, requeue) do
    GenServer.call(@name, {:reject, channel, tag, requeue})
  end

  def publish(exchange_name, message) do
    GenServer.call(@name, {:publish, exchange_name, message})
  end

  def publish(exchange_name, routing_key, message) do
    GenServer.call(@name, {:publish, exchange_name, routing_key, message})
  end

  def publish(channel, exchange_name, routing_key, message) do
    GenServer.call(@name, {:publish, channel, exchange_name, routing_key, message})
  end

  def handle_call({:confirm, channel, tag}, _from, %{adapter: adapter} = state) do
    adapter.confirm(channel, tag)

    {:reply, :ok, state}
  end

  def handle_call({:reject, channel, tag, requeue}, _from, %{adapter: adapter} = state) do
    adapter.reject(channel, tag, requeue: requeue)

    {:reply, :ok, state}
  end

  def handle_call({:publish, exchange_name, message}, _from, state) do
    state.adapter.publish(state.pub_chan, exchange_name, "", message)

    {:reply, :ok, state}
  end

  def handle_call({:publish, exchange_name, routing_key, message}, _from, state) do
    state.adapter.publish(state.pub_chan, exchange_name, routing_key, message)

    {:reply, :ok, state}
  end

  def handle_call({:publish, channel, exchange_name, routing_key, message}, _from, state) do
    state.adapter.publish(channel, exchange_name, routing_key, message)

    {:reply, :ok, state}
  end

  defp rabbitmq_connect(consumers, adapter: adapter, settings: settings) do
    conn = adapter.open(settings)

    start_consumers(consumers, adapter, conn)

    {:ok, %{adapter: adapter, pub_chan: adapter.create_channel(conn)}}
  end

  defp start_consumers(consumers, adapter, conn) do
    Enum.each consumers, fn (consumer) ->
      subscribe_chan = adapter.create_channel(conn)
      publish_chan = respond_to(adapter, conn, consumer.connection)

      connection = ConsumerConnection.build(subscribe_chan, publish_chan)

      {:ok, pid} = ConsumerSupervisor.start_consumer(consumer, connection)

      adapter.subscribe(subscribe_chan, pid, consumer)
    end
  end

  defp respond_to(adapter, conn, %{respond_to: exchange}) do
    chan = adapter.create_channel(conn)
    adapter.respond_to(chan, exchange)

    chan
  end
  defp respond_to(_adapter, _conn, _settings), do: nil
end
