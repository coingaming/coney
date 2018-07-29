defmodule Coney.PoolSupervisor do
  use Supervisor

  alias Coney.{ConsumerSupervisor, ConnectionServer}

  def start_link(consumers, settings) do
    Supervisor.start_link(__MODULE__, [consumers, settings])
  end

  def init([consumers, settings]) do
    children = [
      supervisor(ConsumerSupervisor, []),
      worker(ConnectionServer, [self(), consumers, settings])
    ]

    supervise(children, strategy: :one_for_all)
  end

  def consumer_supervisor_pid(pool_pid) do
    {_, pid, _, _} =
      pool_pid
      |> Supervisor.which_children()
      |> Enum.find(fn
        {ConsumerSupervisor, _, _, _} -> true
        _ -> false
      end)

    pid
  end
end
