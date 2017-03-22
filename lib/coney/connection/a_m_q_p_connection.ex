defmodule Coney.AMQPConnection do
  @type conn :: any
  @type chan :: any

  @callback open(Map.t) :: conn
  @callback create_channel(conn) :: chan
  @callback subscribe(chan, pid, atom) :: tuple
  @callback respond_to(chan, {atom, String.t}) :: any
  @callback publish(chan, String.t, String.t, String.t) :: any
  @callback confirm(chan, String.t) :: any
  @callback reject(chan, String.t, nonempty_list) :: any
end
