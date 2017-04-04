defmodule Coney.Test.FakeConnection do
  @behaviour Coney.AMQPConnection

  def open(_) do
    :conn
  end

  def create_channel(:conn) do
    :chan
  end

  def subscribe(:chan, _, _) do
    {:ok, :subscribed}
  end

  def respond_to(:chan, _exchange) do
    nil
  end

  def publish(:chan, _exchange, _routing_key, _message) do
    :published
  end

  def confirm(_, _) do
    :confirmed
  end

  def reject(_, _, _) do
    :rejected
  end
end
