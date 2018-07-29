defmodule Coney.ConnectionServer do
  use GenServer

  alias Coney.{ConsumerSupervisor, ConsumerConnection, PoolSupervisor, ApplicationSupervisor}

  def start_link(pool_pid, consumers, settings) do
    GenServer.start_link(__MODULE__, [pool_pid, consumers, settings])
  end

  def init([pool_pid, consumers, settings]) do
    send(self(), :after_init)

    {:ok, %{pool_pid: pool_pid, consumers: consumers, settings: settings}}
  end

  def handle_info(:after_init, %{pool_pid: pool_pid, consumers: consumers, settings: settings}) do
    rabbitmq_connect(pool_pid, consumers, settings)
  end

  def confirm(pid, channel, tag) do
    GenServer.call(pid, {:confirm, channel, tag})
  end

  def reject(pid, channel, tag, requeue) do
    GenServer.call(pid, {:reject, channel, tag, requeue})
  end

  def publish(exchange_name, message) do
    pid = ApplicationSupervisor.connection_pid()

    GenServer.call(pid, {:publish, exchange_name, message})
  end

  def publish(exchange_name, routing_key, message) do
    pid = ApplicationSupervisor.connection_pid()

    GenServer.call(pid, {:publish, exchange_name, routing_key, message})
  end

  def publish(pid, channel, exchange_name, routing_key, message) do
    GenServer.call(pid, {:publish, channel, exchange_name, routing_key, message})
  end

  def handle_call({:confirm, channel, tag}, _from, %{adapter: adapter} = state) do
    adapter.confirm(channel, tag)

    {:reply, :confirmed, state}
  end

  def handle_call({:reject, channel, tag, requeue}, _from, %{adapter: adapter} = state) do
    adapter.reject(channel, tag, requeue: requeue)

    {:reply, :rejected, state}
  end

  def handle_call(
        {:publish, exchange_name, message},
        _from,
        %{adapter: adapter, pub_chan: pub_chan} = state
      ) do
    adapter.publish(pub_chan, exchange_name, "", message)

    {:reply, :published, state}
  end

  def handle_call({:publish, exchange_name, routing_key, message}, _from, state) do
    state.adapter.publish(state.pub_chan, exchange_name, routing_key, message)

    {:reply, :published, state}
  end

  def handle_call({:publish, channel, exchange_name, routing_key, message}, _from, state) do
    state.adapter.publish(channel, exchange_name, routing_key, message)

    {:reply, :published, state}
  end

  defp rabbitmq_connect(pool_pid, consumers, adapter: adapter, settings: settings) do
    conn = adapter.open(settings)
    start_consumers(pool_pid, consumers, adapter, conn)

    {:noreply, %{adapter: adapter, pub_chan: adapter.create_channel(conn), pool_pid: pool_pid}}
  end

  defp start_consumers(pool_pid, consumers, adapter, conn) do
    consumer_supervisor_pid = PoolSupervisor.consumer_supervisor_pid(pool_pid)

    Enum.each(consumers, fn consumer ->
      subscribe_chan = adapter.create_channel(conn)
      publish_chan = respond_to(adapter, conn, consumer.connection)

      connection = ConsumerConnection.build(self(), subscribe_chan, publish_chan)

      {:ok, pid} = ConsumerSupervisor.start_consumer(consumer_supervisor_pid, consumer, connection)

      adapter.subscribe(subscribe_chan, pid, consumer)
    end)
  end

  defp respond_to(adapter, conn, %{respond_to: exchange}) do
    chan = adapter.create_channel(conn)
    adapter.respond_to(chan, exchange)

    chan
  end

  defp respond_to(_adapter, _conn, _settings), do: nil
end
