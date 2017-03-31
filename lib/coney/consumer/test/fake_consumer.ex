defmodule Coney.Test.FakeConsumer do
  def prefetch_count, do: 10
  def exchange, do: {:fanout, "test_exchange"}
  def queue, do: "test_queue"

  def connection do
    %{
      prefetch_count: 10,
      subscribe:      {:fanout, "subscribe_exchange", "queue"},
      respond_to:     {:fanout, "response_exchange"}
    }
  end

  def parse(payload) do
    payload
  end

  def process(payload) do
    case payload do
      :error     -> {:error, "Error happen"}
      :exception -> raise "Exception happen"
      :ok        -> {:ok, :result}
      :reply     -> {:reply, :result}
    end
  end

  def error_happen(_exception, _payload) do
    :handled
  end
end
