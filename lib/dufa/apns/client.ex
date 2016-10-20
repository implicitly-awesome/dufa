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

  @doc """
  Returns the `client` ssl configuration.
  """
  @spec current_ssl_config(pid()) :: Dufa.APNS.SSLConfig.t
  def current_ssl_config(client) do
    :sys.get_state(client)[:config]
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

  def handle_cast({:push, push_message, opts, on_response_callback}, %{apns_socket: apns_socket, device_token: device_token} = state) do
    push_state = %{
      apns_socket: apns_socket,
      device_token: device_token,
      push_message: push_message,
      opts: opts,
      on_response_callback: on_response_callback
    }

    {:ok, worker} = Dufa.APNS.PushWorker.start_link(push_state)

    if opts[:delay] && opts[:delay] >= 1 do
      Process.send_after(worker, :push, opts[:delay] * 1000)
    else
      Process.send_after(worker, :push, 1)
    end

    {:noreply, state}
  end
end
