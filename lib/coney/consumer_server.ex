defmodule Coney.ConsumerServer do
  @moduledoc """
  GenServer for handling RabbitMQ messages. Spawns and monitors one task per message
  and forwards the response to `ConnectionServer`.
  """

  use GenServer

  alias Coney.{ConnectionServer, ConsumerExecutor, ExecutionTask}

  require Logger

  def child_spec([consumer]) do
    %{
      id: consumer,
      start: {__MODULE__, :start_link, [[consumer]]}
    }
  end

  def start_link([consumer]) do
    GenServer.start_link(__MODULE__, [consumer], name: consumer)
  end

  @impl GenServer
  def init([consumer]) do
    chan = ConnectionServer.subscribe(consumer)

    Logger.info("[Coney] - Started consumer #{inspect(consumer)}")

    {:ok, %{consumer: consumer, chan: chan, tasks: %{}}}
  end

  @impl GenServer
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

    {_pid, ref} = spawn_monitor(ConsumerExecutor, :consume, [task])

    state = put_in(state.tasks[ref], %{chan: chan, tag: tag})

    {:noreply, state}
  end

  # Received after the task completed successfully
  def handle_info({:DOWN, ref, _, _, :normal = _reason}, state) do
    {_task, state} = pop_in(state.tasks[ref])
    Process.demonitor(ref, [:flush])

    {:noreply, state}
  end

  # Received if the task terminate abnormally
  def handle_info({:DOWN, ref, _, _, reason}, state) do
    Logger.error("[#{__MODULE__}] Error processing message with reason: #{inspect(reason)}")
    {task, state} = pop_in(state.tasks[ref])
    # Reject message
    reject(task)

    Process.demonitor(ref, [:flush])
    {:noreply, state}
  end

  defp reject(%{chan: chan, tag: tag}), do: ConnectionServer.reject(chan, tag, false)
  defp reject(_task), do: :ok
end
