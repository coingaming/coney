defmodule Coney.ConsumerSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      worker(Coney.ConsumerServer, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  def start_consumer(consumer, connection) do
    Supervisor.start_child(__MODULE__, [consumer, connection])
  end
end
