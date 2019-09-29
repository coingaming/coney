defmodule Coney.FakeConnection do
  def open(_) do
    :conn
  end

  def create_channel(_) do
    :chan
  end

  def subscribe(_, _, _) do
    {:ok, :subscribed}
  end

  def respond_to(_, _) do
    nil
  end

  def publish(_, _, _, _) do
    :published
  end

  def confirm(_, _) do
    :confirmed
  end

  def reject(_, _, _) do
    :rejected
  end

  def init_topology(_, _) do
    :ok
  end
end
