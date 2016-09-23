defmodule APNS.ClientTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, client} = Dufa.APNS.Client.start_link
    {:ok, client: client}
  end

  test "stop/1: stops a client", %{client: client} do
    Dufa.APNS.Client.stop(client)
    refute Process.alive?(client)
  end

  test "it pongs", %{client: client} do
    assert Dufa.APNS.Client.ping(client, "hello") == {:pong, "hello"}
  end
end
