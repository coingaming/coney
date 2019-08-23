defmodule Coney.ApplicationSupervisor do
  use Supervisor

  alias Coney.{HealthCheck.ConnectionRegistry, ConsumerSupervisor, ConnectionServer}

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

    children = [
      supervisor(ConsumerSupervisor, []),
      worker(ConnectionServer, [consumers, settings])
    ]

    supervise(children, strategy: :one_for_one)
  end

  def settings do
    [
      adapter: Application.get_env(:coney, :adapter),
      settings: get_config(:settings, :settings),
      topology: get_config(:topology, :topology, %{exchanges: [], queues: []})
    ]
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

  defp get_config(key, callback, default \\ false) do
    config = Application.get_env(:coney, key)

    cond do
      is_map(config) ->
        config

      is_atom(config) ->
        apply(config, callback, [])

      default ->
        default

      true ->
        raise "Please, specify #{Atom.to_string(key)} via config file or module"
    end
  end
end
