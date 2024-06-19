defmodule Coney.ConnectionServer do
  use GenServer

  require Logger

  alias Coney.{
    ConsumerSupervisor,
    HealthCheck.ConnectionRegistry
  }

  defmodule State do
    defstruct [:consumers, :adapter, :settings, :amqp_conn, :topology]
  end

  def start_link([consumers, [adapter: adapter, settings: settings, topology: topology]]) do
    GenServer.start_link(__MODULE__, [consumers, adapter, settings, topology], name: __MODULE__)
  end

  def init([consumers, adapter, settings, topology]) do
    send(self(), :after_init)

    ConnectionRegistry.associate(self())

    {:ok, %State{consumers: consumers, adapter: adapter, settings: settings, topology: topology}}
  end

  def confirm(channel, tag) do
    GenServer.call(__MODULE__, {:confirm, channel, tag})
  end

  def reject(channel, tag, requeue) do
    GenServer.call(__MODULE__, {:reject, channel, tag, requeue})
  end

  def publish(exchange_name, message) do
    GenServer.call(__MODULE__, {:publish, exchange_name, message})
  end

  def publish(exchange_name, routing_key, message) do
    GenServer.call(__MODULE__, {:publish, exchange_name, routing_key, message})
  end

  def handle_info(:after_init, state) do
    rabbitmq_connect(state)
  end

  def handle_info({:DOWN, _, :process, _pid, reason}, state) do
    ConnectionRegistry.disconnected(self())
    Logger.error("#{__MODULE__} (#{inspect(self())}) connection lost: #{inspect(reason)}")
    rabbitmq_connect(state)
  end

  def terminate(_reason, %{amqp_conn: conn, adapter: adapter} = _state) do
    :ok = adapter.close(conn)
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

      {:ok, pid} = ConsumerSupervisor.start_consumer(consumer, subscribe_chan)
      adapter.subscribe(subscribe_chan, pid, consumer)

      Logger.debug("#{inspect(consumer)} (#{inspect(pid)}) started")
    end)
  end
end
