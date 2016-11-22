defmodule APNS.ClientTest do
  use ExUnit.Case, async: false

  alias Dufa.APNS.Client
  alias Dufa.APNS.SSLConfig

  defmodule TestHTTP2Client do
    @behaviour Dufa.Network.HTTP2.Client

    def uri(:apns, :prod), do: to_char_list("apns_prod_uri")
    def uri(:apns, :dev), do: to_char_list("apns_dev_uri")

    def open_socket(_, _, _), do: {:ok, nil}

    def send_request(_, _, _), do: :ok

    def get_response(_, _), do: :ok
  end

  test "stop/1: stops a client" do
    {:ok, client} = Client.start_link(TestHTTP2Client, "device_token", SSLConfig.new)
    assert Process.alive?(client)
    Client.stop(client)
    refute Process.alive?(client)
  end

  test "current_ssl_config/1: returns ssl config of the client" do
    ssl_config = SSLConfig.new(%{
      mode: :dev,
      cert: :qwe,
      key:  :rty
    })

    {:ok, client} = Client.start_link(TestHTTP2Client, "device_token", ssl_config)
    assert Client.current_ssl_config(client).mode == :dev
    assert Client.current_ssl_config(client).cert == :qwe
    assert Client.current_ssl_config(client).key  == :rty
  end
end
