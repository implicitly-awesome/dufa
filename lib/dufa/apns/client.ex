defmodule Dufa.APNS.Client do
  use GenServer

  def start_link, do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok), do: {:ok, %{}}

  def stop(client), do: GenServer.stop(client)

  def ping(client, payload) do
    GenServer.call(client, {:ping, payload})
  end

  def handle_call({:ping, payload}, _from, state) do
    {:reply, {:pong, payload}, state}
  end
end
