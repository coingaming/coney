defmodule Coney.ApplicationSupervisor do
  use Supervisor

  alias Coney.{ConsumerSupervisor, ConnectionServer}

  def start_link(consumers) do
    Supervisor.start_link(__MODULE__, [consumers], name: __MODULE__)
  end

  def init([consumers]) do
    IO.inspect("SDGSGS")

    children = [
      supervisor(ConsumerSupervisor, []),
      worker(ConnectionServer, [consumers, settings()])
    ]

    supervise(children, strategy: :one_for_all)
  end

  def settings do
    [
      adapter: Application.get_env(:coney, :adapter),
      settings: Application.get_env(:coney, :settings)
    ]
  end
end
