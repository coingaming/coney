defmodule Coney.ApplicationSupervisor do
  @moduledoc """
  Supervisor responsible of `ConnectionServer` and `ConsumerSupervisor`.

  Main entry point of the application.
  """

  use Supervisor

  alias Coney.{ConsumerSupervisor, ConnectionServer}

  def start_link(consumers) do
    Supervisor.start_link(__MODULE__, [consumers], name: __MODULE__)
  end

  def child_spec(_args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [Application.get_env(:coney, :workers, [])]}
    }
  end

  @impl Supervisor
  def init([consumers]) do
    settings = settings()

    {enabled?, settings} = Keyword.pop!(settings, :enabled)

    children =
      if enabled? do
        [
          {ConnectionServer, [settings]},
          {ConsumerSupervisor, [consumers]}
        ]
      else
        []
      end

    Supervisor.init(children, strategy: :one_for_one)
  end

  def settings do
    [
      adapter: Application.get_env(:coney, :adapter, Coney.RabbitConnection),
      enabled: Application.get_env(:coney, :enabled, true),
      settings: get_config(:settings, :settings),
      topology: get_config(:topology, :topology, %{exchanges: [], queues: []})
    ]
  end

  defp get_config(key, callback, default \\ false) do
    config = Application.get_env(:coney, key)

    cond do
      is_map(config) ->
        config

      is_nil(config) ->
        default

      is_atom(config) ->
        apply(config, callback, [])

      true ->
        raise "Please, specify #{Atom.to_string(key)} via config file or module"
    end
  end
end
