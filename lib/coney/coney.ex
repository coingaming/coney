defmodule Coney do
  alias Coney.{ConnectionServer, ConnectionRegistry}

  @spec publish(String.t(), String.t()) :: :published | {:error, :no_connected_servers}
  def publish(exchange_name, message) do
    ConnectionServer.publish(exchange_name, message)
  end

  @spec publish(String.t(), String.t(), String.t()) :: :published | {:error, :no_connected_servers}
  def publish(exchange_name, routing_key, message) do
    ConnectionServer.publish(exchange_name, routing_key, message)
  end

  @spec status() :: list({pid(), :pending | :connected | :disconnected})
  def status do
    ConnectionRegistry.status()
  end
end
