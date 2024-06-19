defmodule Coney.ConsumerExecutor do
  require Logger

  alias Coney.{ConnectionServer, ExecutionTask}

  def consume(%ExecutionTask{consumer: consumer, payload: payload, meta: meta} = task) do
    payload
    |> consumer.parse(meta)
    |> consumer.process(meta)
    |> handle_result(task)
  end

  defp handle_result(:ok, task), do: ack(task)

  defp handle_result(:reject, task), do: reject(task)

  defp handle_result(:redeliver, task), do: redeliver(task)

  defp handle_result({:reply, response}, task), do: reply(task, response)

  defp ack(%ExecutionTask{tag: tag, chan: chan}) do
    ConnectionServer.confirm(chan, tag)
  end

  defp reply(%ExecutionTask{settings: %{respond_to: exchange_name}} = task, response) do
    ack(task)
    send_message(exchange_name, response)
  end

  defp redeliver(%ExecutionTask{tag: tag, chan: chan}) do
    ConnectionServer.reject(chan, tag, true)
  end

  defp reject(%ExecutionTask{tag: tag, chan: chan}) do
    ConnectionServer.reject(chan, tag, false)
  end

  defp send_message(exchange, {routing_key, response}) do
    ConnectionServer.publish(exchange, routing_key, response)
  end

  defp send_message(exchange, response) do
    send_message(exchange, {"", response})
  end
end
