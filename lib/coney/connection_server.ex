defmodule Coney.ConnectionServer do
  use GenServer

  require Logger

  alias Coney.{ConsumerSupervisor, ConsumerConnection, PoolSupervisor, ApplicationSupervisor}

  defmodule State do
    defstruct [:pool_pid, :consumers, :adapter, :settings, :amqp_conn]
  end

  def start_link(pool_pid, consumers, adapter: adapter, settings: settings) do
    GenServer.start_link(__MODULE__, [pool_pid, consumers, adapter, settings])
  end

  def init([pool_pid, consumers, adapter, settings]) do
    send(self(), :after_init)

    {:ok, %State{pool_pid: pool_pid, consumers: consumers, adapter: adapter, settings: settings}}
  end

  def confirm(pid, channel, tag) do
    GenServer.call(pid, {:confirm, channel, tag})
  end

  def reject(pid, channel, tag, requeue) do
    GenServer.call(pid, {:reject, channel, tag, requeue})
  end

  def publish(exchange_name, message) do
    pid = ApplicationSupervisor.connection_server_pid()

    GenServer.call(pid, {:publish, exchange_name, message})
  end

  def publish(exchange_name, routing_key, message) do
    pid = ApplicationSupervisor.connection_server_pid()

    publish(pid, exchange_name, routing_key, message)
  end

  def publish(pid, exchange_name, routing_key, message) do
    GenServer.call(pid, {:publish, exchange_name, routing_key, message})
  end

  def handle_info(:after_init, state) do
    rabbitmq_connect(state)
  end

  def handle_info({:DOWN, _, :process, _pid, reason}, state) do
    Logger.error("#{__MODULE__} (#{inspect(self())}) connection lost: #{inspect(reason)}")
    rabbitmq_connect(state)
  end

  def handle_call({:confirm, channel, tag}, _from, %State{adapter: adapter} = state) do
    adapter.confirm(channel, tag)

    {:reply, :confirmed, state}
  end

  def handle_call({:reject, channel, tag, requeue}, _from, %State{adapter: adapter} = state) do
    adapter.reject(channel, tag, requeue: requeue)

    {:reply, :rejected, state}
  end

  def handle_call(
        {:publish, exchange_name, message},
        _from,
        %State{adapter: adapter, amqp_conn: conn} = state
      ) do
    adapter.publish(conn, exchange_name, "", message)

    {:reply, :published, state}
  end

  def handle_call({:publish, exchange_name, routing_key, message}, _from, state) do
    state.adapter.publish(state.amqp_conn, exchange_name, routing_key, message)

    {:reply, :published, state}
  end

  defp rabbitmq_connect(
         %State{
           pool_pid: pool_pid,
           consumers: consumers,
           adapter: adapter,
           settings: settings
         } = state
       ) do
    conn = adapter.open(settings)
    start_consumers(pool_pid, consumers, adapter, conn)

    {:noreply, %State{state | amqp_conn: conn}}
  end

  defp start_consumers(pool_pid, consumers, adapter, conn) do
    consumer_supervisor_pid = PoolSupervisor.consumer_supervisor_pid(pool_pid)

    Enum.each(consumers, fn consumer ->
      subscribe_chan = adapter.create_channel(conn)
      connection = ConsumerConnection.build(self(), subscribe_chan)

      {:ok, pid} = ConsumerSupervisor.start_consumer(consumer_supervisor_pid, consumer, connection)
      adapter.subscribe(subscribe_chan, pid, consumer)

      Logger.debug("#{inspect(consumer)} (#{inspect(pid)}) started")
    end)
  end
end
