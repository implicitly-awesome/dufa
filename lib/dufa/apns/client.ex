defmodule Dufa.APNS.Client do
  use GenServer
  require Logger

  alias Dufa.APNS.PushMessage
  alias Dufa.HTTP2Client

  def start_link(device_token, ssl_config) do
    GenServer.start_link(__MODULE__, {:ok, device_token, ssl_config})
  end

  def init({:ok, device_token, ssl_config}) do
    case HTTP2Client.open_socket(:apns, ssl_config, 0) do
      {:ok, socket} ->
        {:ok, %{
          apns_socket: socket,
          config: ssl_config,
          device_token: device_token
        }}
      {:error, :open_socket, :timeout} ->
        Logger.error """
          Failed to establish SSL connection.
          Is the certificate signed for :#{ssl_config[:mode]} mode?
        """
        {:stop, {:error, :timeout}}
      {:error, :ssl_config, reason} ->
        Logger.error "Invalid SSL Config: #{reason}"
        {:stop, {:error, :invalid_config}}
      _ ->
        Logger.error "Unhandled error."
        {:stop, {:error, :unhandled}}
    end
  end

  def stop(client), do: GenServer.stop(client)

  def push(client, push_message = %PushMessage{}, on_response_callback \\ nil) do
    GenServer.cast(client, {:push, push_message, on_response_callback})
  end

  def handle_cast(:stop, state), do: {:noreply, state}

  def handle_cast({:push, push_message, on_response_callback}, state) do
    do_push(push_message, state)
    state =
      state
      |> Map.put(:push_message, push_message)
      |> Map.put(:on_response_callback, on_response_callback)
    {:noreply, state}
  end

  defp do_push(push_message, %{apns_socket: socket, device_token: device_token}) do
    {:ok, json} = Poison.encode(push_message)

    headers = [
      {":method", "POST"},
      {":path", "/3/device/#{device_token}"},
      {"content-length", "#{byte_size(json)}"}
    ]
    :h2_client.send_request(socket, headers, json)
  end

  def handle_info({:END_STREAM, stream},
                  %{apns_socket: socket,
                    push_message: push_message,
                    on_response_callback: on_response_callback} = state) do
    {:ok, {headers, body}} = :h2_client.get_response(socket, stream)

    handle_response({headers, body}, state, on_response_callback)
  end

  defp fetch_status([]), do: nil
  defp fetch_status([{":status", status} | tail]), do: status
  defp fetch_status([_head | tail]), do: fetch_status(tail)
  defp fetch_status(_), do: nil

  defp handle_response(response, state, on_response_callback \\ nil)
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

  defp fetch_reason(body) do
    {:ok, body} = Poison.decode(body)
    Macro.underscore(body["reason"])
  end

  defp log_error({status, reason}, push_message) do
    Logger.error("#{reason}[#{status}]\n#{inspect(push_message)}")
  end
end
