defmodule Coney.ConsumerServer do
  use GenServer

  alias Coney.{ConsumerExecutor, ExecutionTask}

  def start_link(consumer, chan) do
    GenServer.start_link(__MODULE__, [consumer, chan])
  end

  def init([consumer, chan]) do
    {:ok, %{consumer: consumer, chan: chan}}
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
        %{consumer: consumer, chan: chan} = state
      ) do
    task = ExecutionTask.build(consumer, chan, payload, tag, meta)

    spawn(ConsumerExecutor, :consume, [task])

    {:noreply, state}
  end
end
