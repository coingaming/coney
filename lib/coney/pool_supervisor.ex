defmodule Coney.PoolSupervisor do
  use Supervisor

  alias Coney.{ConsumerSupervisor, ConnectionServer}

  def start_link(consumers, settings) do
    Supervisor.start_link(__MODULE__, [consumers, settings], name: __MODULE__)
  end

  def init([consumers, settings]) do
    children = [
      supervisor(ConsumerSupervisor, []),
      worker(ConnectionServer, [consumers, settings])
    ]

    supervise(children, strategy: :one_for_all)
  end
end
