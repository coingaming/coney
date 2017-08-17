defmodule Coney.ConsumerServer do
  require Logger

  use GenServer

  alias Coney.{ConsumerExecutor, ExecutionTask}

  def start_link(consumer, connection) do
    GenServer.start_link(__MODULE__, [consumer, connection])
  end

  def init([%{worker: consumer}, connection]) do
    Logger.info "ConsumerServer started", [consumer: consumer]
    {:ok, %{consumer: consumer, connection: connection}}
  end

  def init([consumer, connection]) do
    Logger.info "ConsumerServer started", [consumer: consumer]
    {:ok, %{consumer: consumer, connection: connection}}
  end

  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, state) do
    {:noreply, state}
  end

  def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, state) do
    {:stop, :normal, state}
  end

  def handle_info({:basic_cancel_ok, %{consumer_tag: _consumer_tag}}, state) do
    {:noreply, state}
  end

  def handle_info(
    {
      :basic_deliver,
      payload,
      %{delivery_tag: tag, redelivered: redelivered, routing_key: routing_key}
    },
    state
  )
  do
    Logger.info("Message received", [
      tag: tag,
      redelivered: redelivered,
      consumer: state.consumer,
      routing_key: routing_key
    ])

    task = ExecutionTask.build(state.consumer, state.connection, payload, tag, redelivered)

    spawn(ConsumerExecutor, :consume, [task])

    {:noreply, state}
  end
end
