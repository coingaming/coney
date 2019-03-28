defmodule Coney.ApplicationSupervisor do
  use Supervisor

  alias Coney.{PoolSupervisor, HealthCheck.ConnectionRegistry}

  def start_link(consumers) do
    Supervisor.start_link(__MODULE__, [consumers], name: __MODULE__)
  end

  def child_spec(_args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [Application.get_env(:coney, :workers, [])]}
    }
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
      settings: connection_settings()
    ]
  end

  def pool_size do
    Application.get_env(:coney, :pool_size, 1)
  end

  def connection_server_pid do
    case Enum.random(active_servers()) do
      pid when is_pid(pid) ->
        {:ok, pid}

      _ ->
        {:error, :no_connected_servers}
    end
  end

  def active_servers do
    ConnectionRegistry.status()
    |> Stream.filter(fn {_pid, status} -> status == :connected end)
    |> Stream.map(fn {pid, _status} -> pid end)
    |> Enum.to_list()
  end

  defp connection_settings do
    settings = Application.get_env(:coney, :settings)

    cond do
      is_map(settings) ->
        settings

      is_atom(settings) ->
        settings.rabbitmq_settings()

      true ->
        raise "Please, specify connection settings via config file or module"
    end
  end
end
