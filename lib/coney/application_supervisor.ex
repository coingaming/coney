defmodule Coney.ApplicationSupervisor do
  use Supervisor

  alias Coney.PoolSupervisor

  def start_link(consumers) do
    Supervisor.start_link(__MODULE__, [consumers], name: __MODULE__)
  end

  def init([consumers]) do
    settings = settings()
    pool_size = pool_size()

    1..pool_size
    |> Enum.map(&supervisor(PoolSupervisor, [consumers, settings], id: "coney.pool.#{&1}"))
    |> supervise(strategy: :one_for_one)
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
end
