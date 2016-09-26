defmodule Dufa.APNS.Client do
  use GenServer

  def start_link(device_token, ssl_config) do
    GenServer.start_link(__MODULE__, [device_token, ssl_config])
  end

  def init(device_token, ssl_config) do
    {:ok, %{device_token: device_token, ssl_config: ssl_config}}
  end

  def stop(client), do: GenServer.stop(client)

  def ping(client) do
    GenServer.call(client, :ping)
  end

  def handle_call(:ping, _from, state) do
    {:reply, {:pong, state}, state}
  end
end
