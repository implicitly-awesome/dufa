defmodule APNS.PushWorkerTest do
  use ExUnit.Case, async: true

  import Mock

  @apns_production_api_uri "api.push.apple.com"
  @apns_development_api_uri "api.development.push.apple.com"

  alias Dufa.APNS.PushWorker
  alias Dufa.APNS.SSLConfig
  alias Dufa.HTTP2Client
  alias Dufa.APNS.PushMessage
  alias Dufa.APNS.Aps
  alias Dufa.APNS.Alert

  setup do
    token = "device_token"
    alert = %Alert{title: "Title", body: "Body"}
    aps = %Aps{alert: alert}
    push_message = %PushMessage{token: token, aps: aps, custom_data: %{}}
    ssl_config = SSLConfig.new
    ok_headers = [{":status", "200"}]
    ok_body = "all is ok"
    error_headers = [{":status", "400"}]
    {:ok, error_body} = Poison.encode(%{reason: "aaaaa!"})

    {
      :ok,
      ssl_config: ssl_config,
      ok_response: {ok_headers, ok_body},
      error_response: {error_headers, error_body},
      push_message: push_message
    }
  end

  test_with_mock "handle_info(:push): sends push notification and invoke a callback",
                 %{ssl_config: ssl_config, ok_response: {_, ok_body} = ok_response, push_message: push_message},
                 HTTP2Client,
                 [],
                 [open_socket: fn (_, _, _) -> {:ok, nil} end,
                  send_request: fn (_, _, _) -> {:ok, nil} end,
                  get_response: fn (_, _) -> {:ok, ok_response} end] do

    defmodule Callbacker do
      def callback(_push_message, response), do: response
    end

    with_mock(Callbacker, [callback: fn (_, response) -> response end]) do
      callback = fn (push_message, response) -> Callbacker.callback(push_message, response) end

      push_state = %{
        apns_socket: "socket",
        device_token: push_message.token,
        push_message: push_message,
        opts: %{},
        on_response_callback: callback
      }

      {:ok, json} = Poison.encode(push_message)
      headers = [
        {":method", "POST"},
        {":path", "/3/device/#{push_message.token}"},
        {"content-length", "#{byte_size(json)}"}
      ]

      {:ok, worker} = PushWorker.start_link(push_state)

      Process.send(worker, :push, [])
      PushWorker.handle_info({:END_STREAM, nil},
                             %{apns_socket: "socket",
                               push_message: push_message,
                               on_response_callback: callback})

      assert called HTTP2Client.send_request("socket", headers, json)
      assert called Callbacker.callback(push_message, ok_body)
    end
  end

  test_with_mock "handle_info(:push): handles error response and invoke a callback",
                 %{ssl_config: ssl_config, error_response: {_, error_body} = error_response, push_message: push_message},
                 HTTP2Client,
                 [],
                 [open_socket: fn (_, _, _) -> {:ok, nil} end,
                  send_request: fn (_, _, _) -> {:ok, nil} end,
                  get_response: fn (_, _) -> {:ok, error_response} end] do
    defmodule Callbacker do
      def callback(_push_message, response), do: response
    end

    with_mock(Callbacker, [callback: fn (_, response) -> response end]) do
      callback = fn (push_message, response) -> Callbacker.callback(push_message, response) end

      push_state = %{
        apns_socket: "socket",
        device_token: push_message.token,
        push_message: push_message,
        opts: %{},
        on_response_callback: callback
      }

      {:ok, json} = Poison.encode(push_message)
      headers = [
        {":method", "POST"},
        {":path", "/3/device/#{push_message.token}"},
        {"content-length", "#{byte_size(json)}"}
      ]

      {:ok, worker} = PushWorker.start_link(push_state)

      Process.send(worker, :push, [])
      PushWorker.handle_info({:END_STREAM, nil},
                             %{apns_socket: "socket",
                               push_message: push_message,
                               on_response_callback: callback})

      assert called HTTP2Client.send_request("socket", headers, json)
      assert called Callbacker.callback(push_message, {:error, %{"400" => "aaaaa!"}})
    end
  end
end
