defmodule FakeConsumer do
  @behaviour Coney.Consumer

  def connection do
    %{
      prefetch_count: 10,
      queue: "queue"
    }
  end

  def parse(payload, _meta) do
    payload
  end

  def process(payload, _meta) do
    case payload do
      :ok -> :ok
      :reject -> :reject
      :reply -> {:reply, :data}
      :exception -> raise "Exception happen"
    end
  end

  def error_happened(_exception, _payload, _meta) do
    :ok
  end
end
