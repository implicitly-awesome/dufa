defmodule APNS.ClientTest do
  use ExUnit.Case, async: true

  alias Dufa.APNS.SSLConfig

  setup do
    {:ok, client} = Dufa.APNS.Client.start_link("device_token", %SSLConfig{})
    {:ok, client: client}
  end

  test "stop/1: stops a client", %{client: client} do
    Dufa.APNS.Client.stop(client)
    refute Process.alive?(client)
  end

  test "it pongs", %{client: client} do
    assert Dufa.APNS.Client.ping(client) == {:pong, ["device_token", %SSLConfig{}]}
  end

  test "it pongs 2" do
    {:ok, client} = Dufa.APNS.Client.start_link("device_token", %SSLConfig{})
    assert Dufa.APNS.Client.ping(client) == {:pong, ["device_token", %SSLConfig{}]}
  end
end
