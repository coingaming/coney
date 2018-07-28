defmodule Coney.ConsumerServer do
  use GenServer

  alias Coney.{ConsumerExecutor, ExecutionTask}

  def start_link(consumer, connection) do
    GenServer.start_link(__MODULE__, [consumer, connection])
  end

  def init([%{worker: consumer}, connection]) do
    {:ok, %{consumer: consumer, connection: connection}}
  end

  def init([consumer, connection]) do
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
          %{delivery_tag: tag} = meta
        },
        %{consumer: consumer, connection: connection} = state
      ) do
    task = ExecutionTask.build(consumer, connection, payload, tag, meta)

    spawn(ConsumerExecutor, :consume, [task])

    {:noreply, state}
  end
end
