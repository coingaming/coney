defmodule Coney.ConnectionServer do
  use GenServer

  require Logger

  alias Coney.{
    ConsumerSupervisor,
    HealthCheck.ConnectionRegistry
  }

  defmodule State do
    defstruct [:consumers, :adapter, :settings, :amqp_conn, :topology, :channels]
  end

  def start_link([consumers, [adapter: adapter, settings: settings, topology: topology]]) do
    GenServer.start_link(__MODULE__, [consumers, adapter, settings, topology], name: __MODULE__)
  end

  @impl GenServer
  def init([consumers, adapter, settings, topology]) do
    send(self(), :after_init)

    ConnectionRegistry.associate(self())

    {:ok, %State{consumers: consumers, adapter: adapter, settings: settings, topology: topology}}
  end

  def confirm(channel_ref, tag) do
    GenServer.call(__MODULE__, {:confirm, channel_ref, tag})
  end

  def reject(channel_ref, tag, requeue) do
    GenServer.call(__MODULE__, {:reject, channel_ref, tag, requeue})
  end

  def publish(exchange_name, message) do
    GenServer.call(__MODULE__, {:publish, exchange_name, message})
  end

  def publish(exchange_name, routing_key, message) do
    GenServer.call(__MODULE__, {:publish, exchange_name, routing_key, message})
  end

  @impl GenServer
  def handle_info(:after_init, state) do
    rabbitmq_connect(state)
  end

  def handle_info({:DOWN, _, :process, _pid, reason}, state) do
    ConnectionRegistry.disconnected(self())
    Logger.error("#{__MODULE__} (#{inspect(self())}) connection lost: #{inspect(reason)}")
    rabbitmq_connect(state)
  end

  @impl GenServer
  def terminate(_reason, %State{amqp_conn: conn, adapter: adapter} = _state) do
    :ok = adapter.close(conn)
    ConnectionRegistry.terminated(self())
  end

  @impl GenServer
  def handle_call(
        {:confirm, channel_ref, tag},
        _from,
        %State{adapter: adapter, channels: channels} = state
      ) do
    channel = channel_from_ref(channels, channel_ref)
    adapter.confirm(channel, tag)

    {:reply, :confirmed, state}
  end

  def handle_call(
        {:reject, channel_ref, tag, requeue},
        _from,
        %State{adapter: adapter, channels: channels} = state
      ) do
    channel = channel_from_ref(channels, channel_ref)
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
    channels = start_consumers(consumers, adapter, conn)

    ConnectionRegistry.connected(self())

    {:noreply, %State{state | amqp_conn: conn, channels: channels}}
  end

  defp start_consumers(consumers, adapter, conn) do
    consumers
    |> Enum.map(fn consumer ->
      subscribe_chan = adapter.create_channel(conn)
      chan_ref = :erlang.make_ref()

      {:ok, pid} = ConsumerSupervisor.start_consumer(consumer, chan_ref)
      adapter.subscribe(subscribe_chan, pid, consumer)

      Logger.debug("#{inspect(consumer)} (#{inspect(pid)}) started")

      {chan_ref, subscribe_chan}
    end)
    |> Map.new()
  end

  defp channel_from_ref(channels, channel_ref), do: Map.fetch!(channels, channel_ref)
end
