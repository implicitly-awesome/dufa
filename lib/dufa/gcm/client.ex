defmodule Dufa.GCM.Client do
  use GenServer
  require Logger

  alias Dufa.GCM.PushMessage

  @type push_result :: {:error, :unauthorized} |
                       {:error, :unhandled_error} |
                       {:error, {String.t, List.t}} |
                       :ok

  @uri "https://gcm-http.googleapis.com"
  @path "/gcm/send"
  @name :gcm_client

  def start_link(api_key) do
    GenServer.start_link(__MODULE__, {:ok, api_key}, name: @name)
  end

  def init({:ok, api_key}), do: {:ok, %{api_key: api_key}}

  @spec stop() :: :ok
  def stop, do: GenServer.stop(@name)

  @spec push(Dufa.GCM.PushMessage.t, Map.t, fun()) :: {:reply, push_result, Map.t}
  def push(push_message = %PushMessage{}, opts \\ %{}, on_response_callback \\ nil) do
    GenServer.call(@name, {:push, push_message, opts, on_response_callback})
  end

  @spec log_error({String.t, String.t}, Dufa.GCM.PushMessage) :: :ok | {:error, any()}
  defp log_error({status, reason}, push_message) do
    Logger.error("#{reason}[#{status}]\n#{inspect(push_message)}")
  end

  def handle_call({:push, push_message, %{api_key: api_key}, on_response_callback}, _from, state) do
    result = do_push(push_message, api_key, on_response_callback)
    {:reply, result, state}
  end
  def handle_call({:push, push_message, _opts, on_response_callback}, _from, %{api_key: api_key} = state) do
    result = do_push(push_message, api_key, on_response_callback)
    {:reply, result, state}
  end
  def handle_call({:push, _push_message, _opts, _on_response_callback}, _from, state) do
    {:reply, {:error, :api_key_not_found}, state}
  end

  @spec do_push(Dufa.GCM.PushMessage.t, String.t, fun()) :: push_result
  defp do_push(push_message, api_key, on_response_callback) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "key=#{api_key}"}
    ]

    payload = push_message |> Poison.encode!

    result = HTTPoison.post("#{@uri}#{@path}", payload, headers)

    case result do
      {:ok, %HTTPoison.Response{status_code: 200 = status, body: body}} ->
        handle_response(push_message, {status, body}, on_response_callback)
      {:ok, %HTTPoison.Response{status_code: 401}} ->
        Logger.error "Unauthorized API key."
        {:error, :unauthorized}
      _ ->
        Logger.error "Unhandled error."
        {:error, :unhandled_error}
    end
  end

  @spec handle_response(Dufa.GCM.PushMessage.t, {String.t, String.t}, fun()) :: :ok | {:error, {String.t, List.t}}
  defp handle_response(push_message, {status, body}, on_response_callback) do
    errors =
      body
      |> Poison.decode!
      |> Map.get("results", [])
      |> Enum.map(&(handle_result(&1)))
      |> Enum.reject(&(&1 == :ok))

    if Enum.any?(errors) do
      Enum.each(errors, fn {:error, error_message} -> log_error({status, error_message}, push_message) end)
      if on_response_callback, do: on_response_callback.(push_message, {:error, {status, Keyword.values(errors)}})
      {:error, {status, Keyword.values(errors)}}
    else
      if on_response_callback, do: on_response_callback.(push_message, body)
      :ok
    end
  end

  @spec handle_result(Map.t) :: :ok | {:error, String.t}
  defp handle_result(%{"error" => message}), do: {:error, message}
  defp handle_result(_), do: :ok
end
