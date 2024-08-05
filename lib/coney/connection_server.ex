defmodule Coney.ConnectionServer do
  use GenServer

  require Logger

  alias Coney.HealthCheck.ConnectionRegistry

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

    {:ok,
     %State{
       consumers: consumers,
       adapter: adapter,
       settings: settings,
       topology: topology,
       channels: Map.new()
     }}
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

  def subscribe(consumer) do
    GenServer.call(__MODULE__, {:subscribe, consumer})
  end

  @impl GenServer
  def handle_info(:after_init, state) do
    {:noreply, rabbitmq_connect(state)}
  end

  def handle_info({:DOWN, _, :process, _pid, reason}, state) do
    ConnectionRegistry.disconnected(self())
    Logger.error("#{__MODULE__} (#{inspect(self())}) connection lost: #{inspect(reason)}")
    {:noreply, state |> rabbitmq_connect() |> update_channels()}
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
        {:subscribe, consumer},
        {consumer_pid, _tag},
        %State{amqp_conn: conn, adapter: adapter, channels: channels} = state
      ) do
    channel = adapter.create_channel(conn)
    channel_ref = :erlang.make_ref()

    adapter.subscribe(channel, consumer_pid, consumer)

    new_channels = Map.put(channels, channel_ref, {consumer_pid, consumer, channel})

    Logger.debug("#{inspect(consumer)} (#{inspect(consumer_pid)}) started")
    {:reply, channel_ref, %State{state | channels: new_channels}}
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
           adapter: adapter,
           settings: settings,
           topology: topology
         } = state
       ) do
    conn = adapter.open(settings)
    adapter.init_topology(conn, topology)

    ConnectionRegistry.connected(self())

    %State{state | amqp_conn: conn}
  end

  defp channel_from_ref(channels, channel_ref) do
    {_consumer_pid, _consumer, channel} = Map.fetch!(channels, channel_ref)

    channel
  end

  defp update_channels(%State{amqp_conn: conn, adapter: adapter, channels: channels} = state) do
    new_channels =
      Enum.map(channels, fn {channel_ref, {consumer_pid, consumer, _dead_channel}} ->
        new_channel = adapter.create_channel(conn)
        adapter.subscribe(new_channel, consumer_pid, consumer)

        {channel_ref, {consumer_pid, consumer, new_channel}}
      end)
      |> Map.new()

    %State{state | channels: new_channels}
  end
end
