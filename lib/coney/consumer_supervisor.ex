defmodule Coney.ConsumerSupervisor do
  use DynamicSupervisor

  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_consumer(consumer, chan) do
    spec = {Coney.ConsumerServer, [consumer, chan]}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end
