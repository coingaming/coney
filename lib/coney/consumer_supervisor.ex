defmodule Coney.ConsumerSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children = [
      worker(Coney.ConsumerServer, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  def start_consumer(pid, consumer, connection) do
    Supervisor.start_child(pid, [consumer, connection])
  end
end
