defmodule Dufa.GCM.Client do
  @moduledoc """
  The client that incapsulates interaction logic with GCM.
  """

  use GenServer

  require Logger

  alias Dufa.GCM.PushMessage

  @type push_result :: {:ok, %{status: pos_integer(), body: any()}} |
                       {:error, %{status: pos_integer(), body: any()}} |
                       {:error, :unhandled_error}


  @uri_path "https://gcm-http.googleapis.com/gcm/send"

  def start_link do
    GenServer.start_link(__MODULE__, :ok)
  end

  def init(:ok), do: {:ok, %{}}

  @doc """
  Pushes a `push_message` via GCM with provided `opts` options asynchronously.
  Invokes a `on_response_callback` on a response.
  """
  @spec push(pid(), Dufa.GCM.PushMessage.t, map() | nil, ((PushMessage.t, push_result) -> any()) | nil) :: {:noreply, map()}
  def push(client, push_message = %PushMessage{}, opts \\ %{}, on_response_callback \\ nil) do
    GenServer.cast(client, {:push, push_message, opts, on_response_callback})
  end

  # api_key from opts has a priority
  def handle_cast({:push, push_message, opts, on_response_callback}, state) do
    state = if opts[:delay] && opts[:delay] >= 1 do
              Process.send_after(self, :delayed_push, opts[:delay] * 1000)
              state
              |> Map.put(:push_message, push_message)
              |> Map.put(:opts, opts)
              |> Map.put(:on_response_callback, on_response_callback)
            else
              do_push(push_message, api_key_for(opts), on_response_callback)
              send(self, :kill_client)
              state
            end

    {:noreply, state}
  end

  def handle_info(:kill_client, state) do
    {:stop, :normal, state}
  end

  def handle_info(:delayed_push, %{push_message: push_message, opts: opts, on_response_callback: on_response_callback} = state) do
    do_push(push_message, api_key_for(opts), on_response_callback)
    {:stop, :normal, state}
  end

  @doc """
  Resolves api_key depends on passed `opts`.
  """
  @spec api_key_for(map()) :: String.t
  def api_key_for(opts \\ %{}) do
    opts[:api_key] || Application.get_env(:dufa, :gcm_api_key)
  end

  @doc """
  Pushes a `push_message` synchronously via GCM with provided `api_key`.
  Invokes a `on_response_callback` on a response.
  """
  @spec do_push(Dufa.GCM.PushMessage.t, String.t, ((PushMessage.t, push_result) -> any()) | nil) :: push_result
  def do_push(push_message, api_key, on_response_callback \\ nil) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "key=#{api_key}"}
    ]

    payload = Poison.encode!(push_message)
    result = HTTPoison.post("#{@uri_path}", payload, headers)

    case result do
      {:ok, %HTTPoison.Response{status_code: 200 = status, body: body}} ->
        handle_response(push_message, {status, body}, on_response_callback)
      {:ok, %HTTPoison.Response{status_code: 401 = status, body: body}} ->
        Logger.error "Unauthorized API key."
        if on_response_callback, do: on_response_callback.(push_message, {:error, %{status: status, body: body}})
        {:error, :unauthorized}
      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        Logger.error "Push error."
        if on_response_callback, do: on_response_callback.(push_message, {:error, %{status: status, body: body}})
        {:error, %{status: status, body: body}}
      _ ->
        Logger.error "Unhandled error."
        if on_response_callback, do: on_response_callback.(push_message, {:error, :unhandled_error})
        {:error, :unhandled_error}
    end
  end

  @spec handle_response(Dufa.GCM.PushMessage.t,
                        {String.t, String.t},
                        ((PushMessage.t, push_result) -> any()) | nil) :: {:ok, %{status: String.t, body: String.t}} | {:error, %{status: String.t, body: String.t}}
  defp handle_response(push_message, {status, body}, on_response_callback) do
    errors =
      body
      |> Poison.decode!
      |> Map.get("results", [])
      |> Enum.map(&(handle_result(&1)))
      |> Enum.reject(&(&1 == :ok))

    if Enum.any?(errors) do
      Enum.each(errors, fn {:error, error_message} -> log_error({status, error_message}, push_message) end)
      # if on_response_callback, do: on_response_callback.(push_message, {:error, {status, Keyword.values(errors)}})
      if on_response_callback, do: on_response_callback.(push_message, {:error, %{status: status, body: body}})
      # {:error, {status, Keyword.values(errors)}}
      {:error, %{status: status, body: body}}
    else
      # if on_response_callback, do: on_response_callback.(push_message, body)
      if on_response_callback, do: on_response_callback.(push_message, {:ok, %{status: status, body: body}})
      # {:ok, push_message, body}
      {:ok, %{status: status, body: body}}
    end
  end

  @spec handle_result(map()) :: :ok | {:error, String.t}
  defp handle_result(%{"error" => message}), do: {:error, message}
  defp handle_result(_), do: :ok

  @spec log_error({String.t, String.t}, Dufa.GCM.PushMessage) :: :ok | {:error, any()}
  defp log_error({status, reason}, push_message) do
    Logger.error("#{reason}[#{status}]\n#{inspect(push_message)}")
  end
end
