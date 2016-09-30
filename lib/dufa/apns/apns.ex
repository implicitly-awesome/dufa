defmodule Dufa.APNS do
  @moduledoc """
  APNS pusher.
  """

  @behaviour Dufa.Pusher

  @doc """
  Pushes a `push_message` via APNS with provided `opts` options.
  Invokes a `on_response_callback` on a response.
  """
  @spec push(Dufa.APNS.PushMessage.t, Map.t, fun()) :: {:noreply, Map.t}
  def push(push_message, opts \\ %{}, on_response_callback \\ nil)

  def push(push_message, %{mode: _mode} = opts, on_response_callback) do
    stop_and_push(push_message, opts, on_response_callback)
  end

  def push(push_message, %{cert: _cert} = opts, on_response_callback) do
    stop_and_push(push_message, opts, on_response_callback)
  end

  def push(push_message, %{cert_file: _cert_file} = opts, on_response_callback) do
    stop_and_push(push_message, opts, on_response_callback)
  end

  def push(push_message, %{key: _key} = opts, on_response_callback) do
    stop_and_push(push_message, opts, on_response_callback)
  end

  def push(push_message, %{key_file: _key_file} = opts, on_response_callback) do
    stop_and_push(push_message, opts, on_response_callback)
  end

  @spec push(Dufa.APNS.PushMessage.t, Map.t, fun()) :: {:noreply, Map.t}
  defp stop_and_push(push_message, opts, on_response_callback) do
    with {:ok, client} <- Dufa.APNS.Registry.lookup(:apns_registry, push_message.token) do
      Dufa.APNS.Client.stop(client)
    end
    do_push(push_message, opts, on_response_callback)
  end

  @spec push(Dufa.APNS.PushMessage.t, Map.t, fun()) :: {:noreply, Map.t}
  defp do_push(push_message, opts, on_response_callback) do
    :apns_registry
    |> Dufa.APNS.Registry.create(push_message.token, opts)
    |> Dufa.APNS.Client.push(push_message, on_response_callback)
  end
end
