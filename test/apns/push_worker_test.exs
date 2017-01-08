defmodule APNS.PushWorkerTest do
  use ExUnit.Case, async: true

  import Mock

  alias Dufa.APNS.PushWorker
  alias Dufa.APNS.SSLConfig
  alias Dufa.Network.HTTP2.Connection
  alias Dufa.APNS.PushMessage
  alias Dufa.APNS.Aps
  alias Dufa.APNS.Alert

  def error_body, do: Poison.encode!(%{reason: "aaaaa!"})
  def ok_body, do: "all is ok"

  defmodule TestHTTP2Client_Ok do
    @behaviour Dufa.Network.HTTP2.Client

    def uri(:apns, :prod), do: to_char_list("apns_prod_uri")
    def uri(:apns, :dev), do: to_char_list("apns_dev_uri")

    def open_socket(_, _, _), do: {:ok, nil}

    def send_request(_, _, _), do: :ok

    def get_response(_, _) do
      ok_headers = [{":status", "200"}]
      {:ok, {ok_headers, APNS.PushWorkerTest.ok_body}}
    end
  end

  defmodule TestHTTP2Client_Err do
    @behaviour Dufa.Network.HTTP2.Client

    def uri(:apns, :prod), do: to_char_list("apns_prod_uri")
    def uri(:apns, :dev), do: to_char_list("apns_dev_uri")

    def open_socket(_, _, _), do: {:ok, nil}

    def send_request(_, _, _), do: :ok

    def get_response(_, _) do
      error_headers = [{":status", "400"}]
      {:ok, {error_headers, APNS.PushWorkerTest.error_body}}
    end
  end

  setup do
    token = "device_token"
    alert = %Alert{title: "Title", body: "Body"}
    aps = %Aps{alert: alert}
    push_message = %PushMessage{token: token, aps: aps, custom_data: %{}}
    ssl_config = SSLConfig.new

    {
      :ok,
      token: token,
      ssl_config: ssl_config,
      push_message: push_message
    }
  end

  test "handle_info(:push): sends push notification and invokes a callback",
         %{ssl_config: ssl_config, push_message: push_message, token: token} do
    defmodule Callbacker do
      def callback(_push_message, response), do: response
    end

    with_mock(Callbacker, [callback: fn (_, response) -> response end]) do
      callback = fn (push_message, response) -> Callbacker.callback(push_message, response) end

      connection = %Connection{
        client: TestHTTP2Client_Ok,
        provider: :apns,
        socket: nil,
        config: ssl_config
      }

      push_state = %{
        connection: connection,
        device_token: token,
        push_message: push_message,
        opts: %{},
        on_response_callback: callback
      }

      {:ok, worker} = PushWorker.start_link(push_state)

      Process.send(worker, :push, [])
      PushWorker.handle_info({:END_STREAM, nil}, push_state)

      assert called Callbacker.callback(push_message, {:ok, %{status: 200, body: ok_body()}})
    end
  end

  test "handle_info(:push): handles error response and invokes a callback",
         %{ssl_config: ssl_config, token: token, push_message: push_message} do
    defmodule Callbacker do
      def callback(_push_message, response), do: response
    end

    with_mock(Callbacker, [callback: fn (_, response) -> response end]) do
      callback = fn (push_message, response) -> Callbacker.callback(push_message, response) end

      connection = %Connection{
        client: TestHTTP2Client_Err,
        provider: :apns,
        socket: nil,
        config: ssl_config
      }

      push_state = %{
        connection: connection,
        device_token: token,
        push_message: push_message,
        opts: %{},
        on_response_callback: callback
      }

      {:ok, worker} = PushWorker.start_link(push_state)

      Process.send(worker, :push, [])
      PushWorker.handle_info({:END_STREAM, nil}, push_state)

      assert called Callbacker.callback(push_message, {:error, %{status: 400, body: error_body()}})
    end
  end
end
