defmodule ConsumerExecutorTest do
  use ExUnit.Case, async: true

  alias Coney.Test.FakeConsumer
  alias Coney.{ConsumerExecutor, ConsumerConnection, ExecutionTask}

  setup do
    [connection: ConsumerConnection.build(:chan, :chan)]
  end

  test "consumer failed with error", %{connection: connection} do
    task = ExecutionTask.build(FakeConsumer, connection, :error, :tag, false)

    result = ConsumerExecutor.consume(task)

    assert :rejected == result
  end

  test "consumer failed with exception", %{connection: connection} do
    task = ExecutionTask.build(FakeConsumer, connection, :exception, :tag, false)

    result = ConsumerExecutor.consume(task)

    assert :failed == result
  end

  test "consumer successfully done", %{connection: connection} do
    task = ExecutionTask.build(FakeConsumer, connection, :ok, :tag, false)

    result = ConsumerExecutor.consume(task)

    assert :confirmed == result
  end

  test "consumer successfully done with reply", %{connection: connection} do
    task = ExecutionTask.build(FakeConsumer, connection, :reply, :tag, false)

    result = ConsumerExecutor.consume(task)

    assert :replied == result
  end
end
