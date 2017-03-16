defmodule Coney.ApplicationSupervisor do
  use Supervisor

  alias Coney.{ConsumerSupervisor, ConnectionServer, AMQPConnection}

  def start_link(consumers) do
    Supervisor.start_link(__MODULE__, [consumers], name: __MODULE__)
  end

  def init([consumers]) do
    children = [
      supervisor(ConsumerSupervisor, []),
      worker(ConnectionServer, [consumers, Application.get_env(:coney, AMQPConnection)])
    ]

    supervise(children, strategy: :one_for_all)
  end
end
