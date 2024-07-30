defmodule Coney.Connection do
  alias AMQP

  @callback open(settings :: map()) :: {:ok, Connection.t()} | {:error, any()}

  @callback create_channel(Connection.t()) :: Channel.t()

  @callback subscribe(Channel.t(), pid(), consumer :: any()) ::
              {:ok, String.t()} | {:error, :blocked} | {:error, :closing}

  @callback publish(
              conn :: Connection.t(),
              exchange :: String.t(),
              routing_key :: String.t(),
              message :: any()
            ) :: :ok | {:error, any()}

  @callback confirm(Channel.t(), tag :: any()) :: :ok | {:error, any()}

  @callback reject(Channel.t(), tag :: any(), opts :: Keyword.t()) :: :ok | {:error, any()}

  @callback init_topology(Connection.t(), topology :: map()) :: :ok | {:error, Basic.error()}
end
