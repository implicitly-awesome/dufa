defmodule Dufa.APNS.Client do
  @moduledoc """
  The client that holds the connection to APNS and spawns Dufa.APNS.PushWorker on each push.
  """

  use GenServer
  require Logger

  alias Dufa.APNS.PushMessage
  alias Dufa.Network.HTTP2

  @type push_result :: {:ok, %{status: pos_integer(), body: any()}} |
                       {:error, %{status: pos_integer(), body: any()}}

  @type open_socket_result :: {:ok, map()} |
                              {:stop, {:error, :timeout}} |
                              {:stop, {:error, :invalid_config}} |
                              {:stop, {:error, :unhandled}}

  @spec start_link(Dufa.Network.HTTP2.Client.t, String.t, Dufa.APNS.SSLConfig.t) ::
    {:ok, pid} | :ignore | {:error, {:already_started, pid} | any()}
  def start_link(http2_client, device_token, ssl_config) do
    GenServer.start_link(__MODULE__, {:ok, http2_client, device_token, ssl_config})
  end

  @spec init({:ok, Dufa.Network.HTTP2.Client.t, String.t, Dufa.APNS.SSLConfig.t}) :: open_socket_result
  def init({:ok, http2_client, device_token, ssl_config}) do
    case HTTP2.connect(http2_client, :apns, ssl_config) do
      {:ok, connection} ->
        {:ok, %{
          connection: connection,
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
    :sys.get_state(client)[:connection].config
  end

  @doc """
  Stops a `client` process.
  """
  def stop(client), do: GenServer.stop(client)

  @doc """
  Pushes a `push_message` via `client`.
  Invokes `on_response_callback` on a response.
  """
  @spec push(pid(), Dufa.APNS.PushMessage.t, map() | nil, ((PushMessage.t, push_result) -> any()) | nil) :: {:noreply, map()}
  def push(client, push_message = %PushMessage{}, opts \\ %{}, on_response_callback \\ nil) do
    GenServer.cast(client, {:push, push_message, opts, on_response_callback})
  end

  def handle_cast({:push, push_message, opts, on_response_callback}, %{connection: connection, device_token: device_token} = state) do
    push_state = %{
      connection: connection,
      device_token: device_token,
      push_message: push_message,
      opts: opts,
      on_response_callback: on_response_callback
    }

    {:ok, worker} = Dufa.APNS.PushWorker.start_link(push_state)
    Dufa.APNS.PushWorker.push(worker, opts[:delay])

    {:noreply, state}
  end
end
