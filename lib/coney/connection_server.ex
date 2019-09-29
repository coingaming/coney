defmodule Coney.ConnectionServer do
  use GenServer

  require Logger

  alias Coney.{
    ConsumerSupervisor,
    ConsumerConnection,
    ApplicationSupervisor,
    HealthCheck.ConnectionRegistry
  }

  defmodule State do
    defstruct [:consumers, :adapter, :settings, :amqp_conn, :topology]
  end

  def start_link(consumers, adapter: adapter, settings: settings, topology: topology) do
    GenServer.start_link(__MODULE__, [consumers, adapter, settings, topology])
  end

  def init([consumers, adapter, settings, topology]) do
    send(self(), :after_init)

    ConnectionRegistry.associate(self())

    {:ok, %State{consumers: consumers, adapter: adapter, settings: settings, topology: topology}}
  end

  def confirm(pid, channel, tag) do
    GenServer.call(pid, {:confirm, channel, tag})
  end

  def reject(pid, channel, tag, requeue) do
    GenServer.call(pid, {:reject, channel, tag, requeue})
  end

  def publish(exchange_name, message) do
    case ApplicationSupervisor.connection_server_pid() do
      {:ok, pid} ->
        GenServer.call(pid, {:publish, exchange_name, message})

      error ->
        error
    end
  end

  def publish(exchange_name, routing_key, message) do
    case ApplicationSupervisor.connection_server_pid() do
      {:ok, pid} ->
        publish(pid, exchange_name, routing_key, message)

      error ->
        error
    end
  end

  def publish(pid, exchange_name, routing_key, message) do
    GenServer.call(pid, {:publish, exchange_name, routing_key, message})
  end

  def handle_info(:after_init, state) do
    rabbitmq_connect(state)
  end

  def handle_info({:DOWN, _, :process, _pid, reason}, state) do
    ConnectionRegistry.disconnected(self())
    Logger.error("#{__MODULE__} (#{inspect(self())}) connection lost: #{inspect(reason)}")
    rabbitmq_connect(state)
  end

  def terminate(_reason, _state) do
    ConnectionRegistry.terminated(self())
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
           consumers: consumers,
           adapter: adapter,
           settings: settings,
           topology: topology
         } = state
       ) do
    conn = adapter.open(settings)
    adapter.init_topology(conn, topology)
    start_consumers(consumers, adapter, conn)

    ConnectionRegistry.connected(self())

    {:noreply, %State{state | amqp_conn: conn}}
  end

  defp start_consumers(consumers, adapter, conn) do
    Enum.each(consumers, fn consumer ->
      subscribe_chan = adapter.create_channel(conn)
      connection = ConsumerConnection.build(self(), subscribe_chan)

      {:ok, pid} = ConsumerSupervisor.start_consumer(consumer, connection)
      adapter.subscribe(subscribe_chan, pid, consumer)

      Logger.debug("#{inspect(consumer)} (#{inspect(pid)}) started")
    end)
  end
end
