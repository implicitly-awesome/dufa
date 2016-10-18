defmodule Dufa.APNS.Client do
  @moduledoc """
  The client that incapsulates interaction logic with APNS.
  """

  use GenServer
  require Logger

  alias Dufa.APNS.PushMessage
  alias Dufa.HTTP2Client

  @type open_socket_result :: {:ok, Map.t} |
                              {:stop, {:error, :timeout}} |
                              {:stop, {:error, :invalid_config}} |
                              {:stop, {:error, :unhandled}}

  def start_link(device_token, ssl_config) do
    GenServer.start_link(__MODULE__, {:ok, device_token, ssl_config})
  end

  @spec init({:ok, String.t, Dufa.APNS.SSLConfig.t}) :: open_socket_result
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

  @spec log_error({String.t, String.t}, Dufa.APNS.PushMessage) :: :ok | {:error, any()}
  defp log_error({status, reason}, push_message) do
    Logger.error("#{reason}[#{status}]\n#{inspect(push_message)}")
  end

  @doc """
  Stops a `client` process.
  """
  def stop(client), do: GenServer.stop(client)

  @doc """
  Pushes a `push_message` via `client`.
  Invokes `on_response_callback` on a response.
  """
  @spec push(pid(), Dufa.APNS.PushMessage.t, Map.t | nil, fun() | nil) :: {:noreply, Map.t}
  def push(client, push_message = %PushMessage{}, opts \\ %{}, on_response_callback \\ nil) do
    GenServer.cast(client, {:push, push_message, opts, on_response_callback})
  end

  def handle_cast({:push, push_message, opts, on_response_callback}, state) do
    state =
      state
      |> Map.put(:push_message, push_message)
      |> Map.put(:opts, opts)
      |> Map.put(:on_response_callback, on_response_callback)

    if opts[:delay] && opts[:delay] >= 1 do
      Process.send_after(self, :delayed_push, opts[:delay] * 1000)
    else
      do_push(push_message, state)
    end

    {:noreply, state}
  end

  def handle_info(:delayed_push, %{push_message: push_message} = state) do
    do_push(push_message, state)
    {:noreply, state}
  end

  def handle_info({:END_STREAM, stream},
                  %{apns_socket: socket,
                    on_response_callback: on_response_callback} = state) do
    {:ok, {headers, body}} = HTTP2Client.get_response(socket, stream)

    handle_response({headers, body}, state, on_response_callback)
  end

  @spec do_push(Dufa.APNS.PushMessage.t, %{apns_socket: pid(), device_token: String.t}) :: {:noreply, Map.t}
  defp do_push(push_message, %{apns_socket: socket, device_token: device_token}) do
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
