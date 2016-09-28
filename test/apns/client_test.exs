defmodule APNS.ClientTest do
  use ExUnit.Case, async: true

  @apns_production_api_uri "api.push.apple.com"
  @apns_development_api_uri "api.development.push.apple.com"

  alias Dufa.APNS.Client
  alias Dufa.APNS.SSLConfig

  setup do
    {:ok, client} = Client.start_link("device_token", %SSLConfig{})
    {:ok, client: client}
  end

  test "stop/1: stops a client", %{client: client} do
    Client.stop(client)
    refute Process.alive?(client)
  end

  test "it pongs", %{client: client} do
    assert Client.ping(client) == {:pong, ["device_token", %SSLConfig{}]}
  end

  test "it pongs 2" do
    {:ok, client} = Client.start_link("device_token", %SSLConfig{})
    assert Client.ping(client) == {:pong, ["device_token", %SSLConfig{}]}
  end

  test "uri/1: returns APNS uri depend on ssl_config[:mode] option" do
    assert Client.uri(:dev) == @apns_development_api_uri
    assert Client.uri(:prod) == @apns_production_api_uri
  end
end
