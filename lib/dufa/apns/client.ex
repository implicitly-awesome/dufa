defmodule Dufa.APNS.Client do
  use GenServer
  require Logger

  alias Dufa.APNS.PushMessage

  @apns_production_api_uri "api.push.apple.com"
  @apns_development_api_uri "api.development.push.apple.com"

  def start_link(device_token, ssl_config) do
    GenServer.start_link(__MODULE__, {:ok, device_token, ssl_config})
  end

  def init({:ok, device_token, ssl_config}) do
    case open_socket(ssl_config, 0) do
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

  def ping(client) do
    GenServer.call(client, :ping)
  end

  def handle_call(:ping, _from, state) do
    {:reply, {:pong, state}, state}
  end

  def uri(:dev), do: to_char_list(@apns_development_api_uri)
  def uri(:prod), do: to_char_list(@apns_production_api_uri)

  def open_socket(_, 3), do: {:error, :open_cosket, :timeout}
  def open_socket(%{cert: nil}, _tries), do: {:error, :ssl_config, "Need to provide a certificate"}
  def open_socket(%{key: nil}, _tries), do: {:error, :ssl_config, "Need to provide RSA key"}
  def open_socket(%{mode: mode, cert: cert, key: key} = ssl_config, tries) do
    case :h2_client.start_link(:https, uri(mode), socket_config({:cert, cert}, {:key, key})) do
      {:ok, socket} -> {:ok, socket}
      _ -> open_socket(ssl_config, tries + 1)
    end
  end
  def open_socket(_, _), do: {:error, :ssl_config, "Invalid SSL config"}

  defp socket_config(cert, key) do
    [
      cert,
      key,
      {:password, ''},
      {:packet, 0},
      {:reuseaddr, true},
      {:active, true},
      :binary
    ]
  end


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

  def do_push(push_message, %{apns_socket: socket, device_token: device_token}) do
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
                    on_response_callback: nil} = state) do
    {:ok, {headers, body}} = :h2_client.get_response(socket, stream)

    status = fetch_status(headers)

    case status do
      "200" ->
        {:noreply, state}
      nil ->
        {:noreply, state}
      _ ->
        {:noreply, state}
    end
  end

  def handle_info({:END_STREAM, stream},
                  %{apns_socket: socket,
                    push_message: push_message,
                    on_response_callback: on_response_callback} = state) when not is_nil(on_response_callback) do
    {:ok, {headers, body}} = :h2_client.get_response(socket, stream)

    status = fetch_status(headers)

    case status do
      "200" ->
        on_response_callback.(push_message, body)
        {:noreply, Map.delete(state, :on_response_callback)}
      nil ->
        {:noreply, state}
      error ->
        on_response_callback.(push_message, {:error, error})
        {:noreply, Map.delete(state, :on_response_callback)}
    end
  end

  defp fetch_status([]), do: nil
  defp fetch_status([{":status", status} | tail]), do: status
  defp fetch_status([_head | tail]), do: fetch_status(tail)
  defp fetch_status(_), do: nil
end
