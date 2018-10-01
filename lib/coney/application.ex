defmodule Coney.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Coney.ApplicationSupervisor, [Application.get_env(:coney, :workers, [])]}
    ]

    opts = [strategy: :one_for_one, name: Coney.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
