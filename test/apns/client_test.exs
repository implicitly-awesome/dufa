defmodule APNS.ClientTest do
  use ExUnit.Case, async: true

  import Mock

  @apns_production_api_uri "api.push.apple.com"
  @apns_development_api_uri "api.development.push.apple.com"

  alias Dufa.APNS.Client
  alias Dufa.APNS.SSLConfig
  alias Dufa.HTTP2Client

  setup do
    ssl_config = SSLConfig.new
    {:ok, ssl_config: ssl_config}
  end

  test_with_mock "stop/1: stops a client",
                 %{ssl_config: ssl_config},
                 HTTP2Client,
                 [],
                 [open_socket: fn (_, _, _) -> {:ok, nil} end] do
    {:ok, client} = Client.start_link("device_token", ssl_config)
    Client.stop(client)
    refute Process.alive?(client)
  end

  # test_with_mock "push/3: ",
  #                %{ssl_config: ssl_config},
  #                HTTP2Client,
  #                [],
  #                [open_socket: fn (_, _, _) -> {:ok, nil} end] do
  #   {:ok, client} = Client.start_link("device_token", ssl_config)
  #
  # end
end
