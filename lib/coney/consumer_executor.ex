defmodule Coney.ConsumerExecutor do
  alias Coney.{ConnectionServer, ExecutionTask, ConsumerConnection}

  def consume(%ExecutionTask{consumer: consumer, payload: payload, meta: meta} = task) do
    try do
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
  end

  defp handle_result(
         result,
         %ExecutionTask{consumer: consumer, settings: settings, connection: connection} = task
       ) do
    case result do
      :ok ->
        ack(task)

      :reject ->
        reject(task)

      :redeliver ->
        redeliver(task)

      {:reply, response} ->
        reply(task, response)
    end
  end

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
