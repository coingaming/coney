## [0.4.2]

### Changes

- `{:reject, reason}` return value:
  Reject message without redelivery.
  
  ```elixir
  defmodule MyConsumer do
    def connection do
      #...
    end
  
    def parse(payload) do
      String.to_integer(payload)
    end
  
    def process(number) do
      if number <= 10 do
        {:ok, "Work done"}
      else
        {:reject, "Number should be less than 10"}
      end
    end
  end
  ```
- Fix warnings about undefined behaviour function publish/2, publish/3
