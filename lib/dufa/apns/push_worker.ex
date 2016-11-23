defmodule Dufa.APNS.PushWorker do
  @moduledoc """
  Worker that incapsulates the interaction logic with APNS.
  Lives temporarily, while the push job get done.
  """

  use GenServer
  require Logger

  alias Dufa.APNS.PushMessage
  alias Dufa.Network.HTTP2
  alias Dufa.Network.HTTP2.Connection

  @type push_result :: {:ok, %{status: pos_integer(), body: any()}} |
                       {:error, %{status: pos_integer(), body: any()}}

  def start_link(push_state) do
    GenServer.start_link(__MODULE__, {:ok, push_state})
  end

  def init({:ok, push_state}) do
    {:ok, push_state}
  end

  @spec log_error({String.t, String.t}, PushMessage.t) :: :ok | {:error, any()}
  defp log_error({status, reason}, push_message) do
    Logger.error("#{reason}[#{status}]\n#{inspect(push_message)}")
  end

  def push(worker, delay) when is_integer(delay) do
    if delay && delay >= 1 do
      Process.send_after(worker, :push, delay * 1000)
    else
      Process.send(worker, :push, [])
    end
  end
  def push(worker, _delay) do
    Process.send(worker, :kill_worker, [])
    :nothing
  end

  def handle_info(:push, %{connection: _connection,
                           push_message: _push_message,
                           opts: _opts,
                           on_response_callback: _on_response_callback} = state) do
    do_push(state)

    {:noreply, state}
  end

  def handle_info(:kill_worker, state) do
    {:stop, :normal, state}
  end

  def handle_info({:END_STREAM, stream},
                  %{connection: connection,
                    on_response_callback: on_response_callback} = state) do
    {:ok, {headers, body}} = HTTP2.get_response(connection, stream)

    handle_response({headers, body}, state, on_response_callback)

    Process.send(self, :kill_worker, [])
    {:noreply, state}
  end

  @spec do_push(%{push_message: PushMessage.t, connection: Connection.t, device_token: String.t}) :: {:noreply, map()}
  defp do_push(%{push_message: push_message, connection: connection, device_token: device_token}) do
    {:ok, json} = Poison.encode(push_message)

    headers = [
      {":method", "POST"},
      {":path", "/3/device/#{device_token}"},
      {"content-length", "#{byte_size(json)}"}
    ]

    headers =
      if push_message.topic do
        headers ++ [{"apns-topic", push_message.topic}]
      else
        headers
      end

    HTTP2.send_request(connection, headers, json)
  end

  @spec fetch_status(list()) :: String.t | nil
  defp fetch_status([]), do: nil
  defp fetch_status([{":status", status} | _tail]), do: String.to_integer(status)
  defp fetch_status([_head | tail]), do: fetch_status(tail)
  defp fetch_status(_), do: nil

  @spec handle_response({list(), String.t}, map(), ((PushMessage.t, push_result) -> any()) | nil) :: {:noreply, map()}
  defp handle_response({headers, body}, state, on_response_callback)
         when (is_function(on_response_callback) or is_nil(on_response_callback)) do
    case status = fetch_status(headers) do
      200 ->
        if on_response_callback, do: on_response_callback.(state.push_message, {:ok, %{status: status, body: body}})
        {:noreply, state}
      nil ->
        {:noreply, state}
      error_status ->
        error_reason = body |> fetch_reason
        {error_status, error_reason} |> log_error(state.push_message)
        if on_response_callback, do: on_response_callback.(state.push_message, {:error, %{status: status, body: body}})
        {:noreply, state}
    end
  end
  defp handle_response(_response, state, _on_response_callback), do: {:noreply, state}

  @spec fetch_reason(String.t) :: String.t
  defp fetch_reason(body) do
    {:ok, body} = Poison.decode(body)
    Macro.underscore(body["reason"])
  end
end
