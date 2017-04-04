ExUnit.start()

Coney.ConnectionServer.start_link([], Application.get_env(:coney, Coney.AMQPConnection))
