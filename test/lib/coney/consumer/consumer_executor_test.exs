defmodule ConsumerExecutorTest do
  use ExUnit.Case, async: true

  alias Coney.{ConsumerExecutor, ConsumerConnection, ExecutionTask}

  defp build_task(message) do
    connection = ConsumerConnection.build(:chan, :chan)
    ExecutionTask.build(FakeConsumer, connection, message, :tag, %{})
  end

  test "reject message" do
    assert :rejected == ConsumerExecutor.consume(build_task(:reject))
  end

  test "consumer failed with exception" do
    assert :confirmed == ConsumerExecutor.consume(build_task(:exception))
  end

  test "consumer successfully done" do
    assert :confirmed == ConsumerExecutor.consume(build_task(:ok))
  end

  test "consumer successfully done with reply" do
    assert :published == ConsumerExecutor.consume(build_task(:reply))
  end
end
