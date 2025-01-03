defmodule Coney.ConnectionServer do
  @moduledoc """
  Handles connections between `ConsumerServer` and the RabbitMQ instance(s).

  This module abstracts away the connection status of RabbitMQ. Instead, when
  a new `ConsumerServer` is started, it requests `ConnectionServer` to open a channel.
  ConnectionServer opens a real amqp channel, keeps a reference to it in its state and
  returns an erlang reference to `ConsumerServer`. When `ConsumerServer` replies (ack/reject)
  an incoming RabbitMQ message it sends the erlang reference to ConnectionServer and then
  ConnectionServer looks up the real channel.

  ConnectionServer can handle RabbitMQ disconnects independently of ConsumerServer.
  When connection is lost and then regained, ConnectionServer simply updates its
  map of {erlang_ref, AMQP.Connection}, ConsumerServer keeps using the same erlang_ref.
  """
  use GenServer

  require Logger

  alias Coney.HealthCheck.ConnectionRegistry

  defmodule State do
    defstruct [:adapter, :settings, :amqp_conn, :topology, :channels]
  end

  def start_link([[adapter: adapter, settings: settings, topology: topology]]) do
    GenServer.start_link(__MODULE__, [adapter, settings, topology], name: __MODULE__)
  end

  @impl GenServer
  def init([adapter, settings, topology]) do
    ConnectionRegistry.associate(self())

    {:ok, %State{adapter: adapter, settings: settings, topology: topology, channels: Map.new()},
     {:continue, nil}}
  end

  @impl true
  def handle_continue(_continue_arg, state) do
    {:noreply, rabbitmq_connect(state)}
  end

  @spec confirm(reference(), any()) :: :confirmed
  def confirm(channel_ref, tag) do
    GenServer.call(__MODULE__, {:confirm, channel_ref, tag})
  end

  @spec reject(reference(), any(), boolean()) :: :rejected
  def reject(channel_ref, tag, requeue) do
    GenServer.call(__MODULE__, {:reject, channel_ref, tag, requeue})
  end

  @spec publish(String.t(), any()) :: :published
  def publish(exchange_name, message) do
    GenServer.call(__MODULE__, {:publish, exchange_name, message})
  end

  @spec publish(String.t(), String.t(), any()) :: :published
  def publish(exchange_name, routing_key, message) do
    GenServer.call(__MODULE__, {:publish, exchange_name, routing_key, message})
  end

  @spec publish_async(String.t(), any()) :: :ok
  def publish_async(exchange_name, message) do
    GenServer.cast(__MODULE__, {:publish, exchange_name, message})
  end

  @spec publish_async(String.t(), String.t(), any()) :: :ok
  def publish_async(exchange_name, routing_key, message) do
    GenServer.cast(__MODULE__, {:publish, exchange_name, routing_key, message})
  end

  @spec subscribe(any()) :: reference()
  def subscribe(consumer) do
    GenServer.call(__MODULE__, {:subscribe, consumer})
  end

  @impl GenServer
  def handle_info({:DOWN, _, :process, _pid, reason}, state) do
    ConnectionRegistry.disconnected(self())
    Logger.error("#{__MODULE__} (#{inspect(self())}) connection lost: #{inspect(reason)}")
    {:noreply, state |> rabbitmq_connect() |> update_channels()}
  end

  @impl GenServer
  def terminate(_reason, %State{amqp_conn: conn, adapter: adapter, channels: channels} = _state) do
    Logger.info("[Coney] - Terminating #{inspect(conn)}")
    close_channels(channels, adapter)
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

  @impl GenServer
  def handle_cast({:publish, exchange_name, message}, %State{} = state) do
    state.adapter.publish(state.amqp_conn, exchange_name, "", message)

    {:noreply, state}
  end

  def handle_cast({:publish, exchange_name, routing_key, message}, %State{} = state) do
    state.adapter.publish(state.amqp_conn, exchange_name, routing_key, message)

    {:noreply, state}
  end

  defp rabbitmq_connect(
         %State{
           adapter: adapter,
           settings: settings,
           topology: topology
         } = state
       ) do
    conn = adapter.open(settings)
    Process.monitor(conn.pid)
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
      Map.new(channels, fn {channel_ref, {consumer_pid, consumer, _dead_channel}} ->
        new_channel = adapter.create_channel(conn)
        adapter.subscribe(new_channel, consumer_pid, consumer)

        {channel_ref, {consumer_pid, consumer, new_channel}}
      end)

    Logger.info("[Coney] - Connection re-restablished for #{inspect(conn)}")

    %State{state | channels: new_channels}
  end

  defp close_channels(channels, adapter) do
    Enum.each(channels, fn {_channel_ref, {_consumer_pid, _consumer, channel}} ->
      adapter.close_channel(channel)
    end)

    Logger.info("[Coney] - Closed #{map_size(channels)} channels")
  end
end
