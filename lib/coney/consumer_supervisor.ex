defmodule Coney.ConsumerSupervisor do
  use Supervisor

  alias Coney.ConsumerServer

  def start_link([consumers]) do
    Supervisor.start_link(__MODULE__, [consumers], name: __MODULE__)
  end

  @impl Supervisor
  def init([consumers]) do
    children = Enum.map(consumers, fn consumer -> {ConsumerServer, [consumer]} end)

    Supervisor.init(children, strategy: :one_for_one)
  end
end
