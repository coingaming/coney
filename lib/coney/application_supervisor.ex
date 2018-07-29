defmodule Coney.ApplicationSupervisor do
  use Supervisor

  alias Coney.{PoolSupervisor, ConnectionServer}

  def start_link(consumers) do
    Supervisor.start_link(__MODULE__, [consumers], name: __MODULE__)
  end

  def init([consumers]) do
    settings = settings()
    pool_size = pool_size()

    1..pool_size
    |> Enum.map(&pool_supervisor(&1, consumers, settings))
    |> supervise(strategy: :one_for_one)
  end

  defp pool_supervisor(i, consumers, settings) do
    supervisor(PoolSupervisor, [consumers, settings], id: "coney.pool.#{i}")
  end

  def settings do
    [
      adapter: Application.get_env(:coney, :adapter),
      settings: Application.get_env(:coney, :settings)
    ]
  end

  def pool_size do
    Application.get_env(:coney, :pool_size, 1)
  end

  def connection_pid do
    {_, pid, _, _} =
      __MODULE__
      |> Supervisor.which_children()
      |> Enum.map(fn {_, pid, _, _} -> pid end)
      |> Enum.random()
      |> Supervisor.which_children()
      |> Enum.find(fn
        {ConnectionServer, _, _, _} -> true
        _ -> false
      end)

    pid
  end
end
