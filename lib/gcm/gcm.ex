defmodule Dufa.GCM do
  @moduledoc """
  Sends push messages with GCM.

  ## Examples

    notification = %Dufa.GCM.Notification{title: "Title", body: "This is a body"}
    push_message = %Dufa.GCM.PushMessage{
      registration_ids: ["your_reg_id"],
      notification: notification},
      data: %{key: "value"}
    }

    Dufa.GCM.push(push_message)
  """

  @uri "https://gcm-http.googleapis.com"
  @path "/gcm/send"

  alias Dufa.GCM.PushMessage

  @spec push(PushMessage.t, Keyword.t) :: :ok | {:error, any}
  @doc """
  Sends a push message.

  Available options are:
    * `:api_key` (override key decalred in the config)
    * `:silent` (sends silent push)
  """
  def push(push_message = %PushMessage{}, opts \\ []) do
    api_key = case Keyword.fetch(opts, :api_key) do
      {:ok, api_key} -> api_key
      _ -> Application.get_env(:dufa, :gcm_api_key)
    end
    if api_key, do: do_push(push_message, api_key, opts), else: {:error, :undefined_api_key}
  end

  defp do_push(push_message, api_key, opts) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "key=#{api_key}"}
    ]

    payload = if Keyword.get(opts, :silent) do
                push_message
                |> Map.delete(:notification)
                |> Poison.encode!
              else
                push_message |> Poison.encode!
              end

    result = HTTPoison.post("#{@uri}#{@path}", payload, headers)

    case result do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        handle_response(body)
      {:ok, %HTTPoison.Response{status_code: 401}} ->
        {:error, :unauthorized}
      _ ->
        {:error, :unhandled_error}
    end
  end

  defp handle_response(body) do
    results =
      body
      |> Poison.decode!
      |> Map.get("results", [])
      |> Enum.map(&(handle_result(&1)))

    errors = Enum.reject(results, &(&1 == :ok))

    if Enum.any?(errors) do
      {:error, Keyword.values(errors)}
    else
      :ok
    end
  end

  defp handle_result(%{"error" => message}), do: {:error, message}
  defp handle_result(_), do: :ok
end
