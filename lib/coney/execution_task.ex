defmodule Coney.ExecutionTask do
  defstruct consumer: nil,
            settings: %{},
            chan: nil,
            payload: nil,
            tag: nil,
            meta: %{}

  def build(%{worker: consumer, connection: settings}, chan, payload, tag, meta) do
    %__MODULE__{
      consumer: consumer,
      settings: settings,
      chan: chan,
      payload: payload,
      tag: tag,
      meta: meta
    }
  end

  def build(consumer, chan, payload, tag, meta) do
    %__MODULE__{
      consumer: consumer,
      settings: consumer.connection(),
      chan: chan,
      payload: payload,
      tag: tag,
      meta: meta
    }
  end
end
