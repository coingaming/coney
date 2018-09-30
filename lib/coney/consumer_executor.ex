defmodule Coney.ConsumerExecutor do
  alias Coney.{ConnectionServer, ExecutionTask, ConsumerConnection}

  def consume(
        %ExecutionTask{consumer: consumer, connection: connection, payload: payload, meta: meta} =
          task
      ) do
    try do
      payload
      |> consumer.parse(meta)
      |> consumer.process(meta)
      |> handle_result(consumer, connection, task)
    rescue
      exception ->
        if function_exported?(consumer, :error_happened, 3) do
          exception
          |> consumer.error_happened(payload, meta)
          |> handle_result(consumer, connection, task)
        else
          reject(connection, task)
        end
    end
  end

  defp handle_result(result, consumer, connection, task) do
    case result do
      :ok ->
        ack(connection, task)

      :reject ->
        reject(connection, task)

      :redeliver ->
        redeliver(connection, task)

      {:reply, response} ->
        reply(consumer, response, connection, task)
    end
  end

  defp ack(
         %ConsumerConnection{connection_server_pid: pid, subscribe_channel: channel},
         %ExecutionTask{
           tag: tag
         }
       ) do
    ConnectionServer.confirm(pid, channel, tag)
  end

  defp reply(%{connection: %{respond_to: exchange_name}}, response, connection, task) do
    ack(connection, task)
    send_message(connection, exchange_name, response)
  end

  defp redeliver(
         %ConsumerConnection{connection_server_pid: pid, subscribe_channel: channel},
         %ExecutionTask{tag: tag}
       ) do
    ConnectionServer.reject(pid, channel, tag, true)
  end

  defp reject(
         %ConsumerConnection{connection_server_pid: pid, subscribe_channel: channel},
         %ExecutionTask{
           tag: tag
         }
       ) do
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
