defmodule Coney.Application do
  use Application

  def start(_type, _args) do
    children =
      [
        Coney.HealthCheck.StatusChecker
      ] ++ app_supervisor()

    opts = [strategy: :one_for_one, name: Coney.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp app_supervisor do
    if auto_start?() do
      [Coney.ApplicationSupervisor]
    else
      []
    end
  end

  defp auto_start? do
    Application.get_env(:coney, :auto_start, true)
  end
end
