defmodule Dufa.APNS.PushWorker do
  use GenServer
  require Logger

  alias Dufa.APNS.PushMessage
  alias Dufa.HTTP2Client

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

  def handle_info(:push, %{apns_socket: _apns_socket,
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
                  %{apns_socket: socket,
                    on_response_callback: on_response_callback} = state) do
    {:ok, {headers, body}} = HTTP2Client.get_response(socket, stream)

    handle_response({headers, body}, state, on_response_callback)

    send(self, :kill_worker)
    {:noreply, state}
  end

  @spec do_push(%{push_message: PushMessage.t, apns_socket: pid(), device_token: String.t}) :: {:noreply, Map.t}
  defp do_push(%{push_message: push_message, apns_socket: socket, device_token: device_token}) do
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

    HTTP2Client.send_request(socket, headers, json)
  end

  @spec fetch_status(List.t) :: String.t | nil
  defp fetch_status([]), do: nil
  defp fetch_status([{":status", status} | _tail]), do: status
  defp fetch_status([_head | tail]), do: fetch_status(tail)
  defp fetch_status(_), do: nil

  @spec handle_response({List.t, String.t}, Map.t, fun()) :: {:noreply, Map.t}
  defp handle_response({headers, body}, state, on_response_callback)
         when (is_function(on_response_callback) or is_nil(on_response_callback)) do
    case fetch_status(headers) do
      "200" ->
        if on_response_callback, do: on_response_callback.(state.push_message, body)
        {:noreply, state}
      nil ->
        {:noreply, state}
      error_status ->
        error_reason = body |> fetch_reason
        {error_status, error_reason} |> log_error(state.push_message)
        if on_response_callback, do: on_response_callback.(state.push_message, {:error, {error_status, error_reason}})
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
