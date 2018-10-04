defmodule Coney.ConsumerExecutor do
  alias Coney.{ConnectionServer, ExecutionTask, ConsumerConnection}

  def consume(%ExecutionTask{consumer: consumer, payload: payload, meta: meta} = task) do
    payload
    |> consumer.parse(meta)
    |> consumer.process(meta)
    |> handle_result(task)
  rescue
    exception ->
      if function_exported?(consumer, :error_happened, 3) do
        exception
        |> consumer.error_happened(payload, meta)
        |> handle_result(task)
      else
        reject(task)
      end
  end

  defp handle_result(:ok, task), do: ack(task)

  defp handle_result(:reject, task), do: reject(task)

  defp handle_result(:redeliver, task), do: redeliver(task)

  defp handle_result({:reply, response}, task), do: reply(task, response)

  defp ack(%ExecutionTask{
         tag: tag,
         connection: %ConsumerConnection{connection_server_pid: pid, subscribe_channel: channel}
       }) do
    ConnectionServer.confirm(pid, channel, tag)
  end

  defp reply(
         %ExecutionTask{connection: connection, settings: %{respond_to: exchange_name}} = task,
         response
       ) do
    ack(task)
    send_message(connection, exchange_name, response)
  end

  defp redeliver(%ExecutionTask{
         tag: tag,
         connection: %ConsumerConnection{connection_server_pid: pid, subscribe_channel: channel}
       }) do
    ConnectionServer.reject(pid, channel, tag, true)
  end

  defp reject(%ExecutionTask{
         tag: tag,
         connection: %ConsumerConnection{connection_server_pid: pid, subscribe_channel: channel}
       }) do
    ConnectionServer.reject(pid, channel, tag, false)
  end

  defp send_message(
         %ConsumerConnection{connection_server_pid: pid},
         exchange,
         {routing_key, response}
       ) do
    ConnectionServer.publish(pid, exchange, routing_key, response)
  end

  defp send_message(connection, exchange, response) do
    send_message(connection, exchange, {"", response})
  end
end
