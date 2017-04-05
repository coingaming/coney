defmodule Coney.Test.FakeConsumer do
  def connection do
    %{
      prefetch_count: 10,
      exchange:       {:fanout, "subscribe_exchange", durable: true},
      queue:          {"queue"},
      respond_to:     {:fanout, "response_exchange", durable: true}
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

  def error_happened(_exception, _payload) do
    :handled
  end
end
