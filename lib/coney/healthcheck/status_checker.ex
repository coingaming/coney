defmodule Coney.HealthCheck.StatusChecker do
  use GenServer

  alias Coney.HealthCheck.ConnectionRegistry

  @interval 500

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_args) do
    ConnectionRegistry.init()

    {:ok, @interval, @interval}
  end

  def handle_info(:timeout, interval) do
    ConnectionRegistry.status()
    |> Keyword.keys()
    |> Enum.each(fn pid ->
      unless Process.alive?(pid) do
        ConnectionRegistry.terminated(pid)
      end
    end)

    {:noreply, interval, interval}
  end
end
