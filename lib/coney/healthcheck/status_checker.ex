defmodule Coney.HealthCheck.StatusChecker do
  use GenServer

  alias Coney.HealthCheck.ConnectionRegistry

  @interval 500

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def child_spec(_args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    }
  end

  def init(_args) do
    ConnectionRegistry.init()

    {:ok, @interval, @interval}
  end

  def handle_info(:timeout, interval) do
    ConnectionRegistry.status()
    |> Enum.each(fn {pid, _} ->
      unless Process.alive?(pid) do
        ConnectionRegistry.terminated(pid)
      end
    end)

    {:noreply, interval, interval}
  end
end
