defmodule Coney.HealthCheck.ConnectionRegistry do
  def init do
    :ets.new(__MODULE__, [:set, :named_table, :public, read_concurrency: true])
  end

  def associate(pid) do
    :ets.insert(__MODULE__, {pid, :pending})
  end

  def connected(pid) do
    :ets.update_element(__MODULE__, pid, {2, :connected})
  end

  def disconnected(pid) do
    :ets.update_element(__MODULE__, pid, {2, :disconnected})
  end

  def terminated(pid) do
    :ets.delete(__MODULE__, pid)
  end

  def status do
    :ets.tab2list(__MODULE__)
  end
end
