defmodule Coney.ConsumerSupervisor do
  use Supervisor

  @name __MODULE__

  def start_link do
    Supervisor.start_link(@name, [], name: @name)
  end

  def init([]) do
    children = [
      worker(Coney.ConsumerServer, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  def start_consumer(consumer, connection) do
    Supervisor.start_child(@name, [consumer, connection])
  end
end
