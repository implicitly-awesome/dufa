defmodule Dufa.APNS do
  @behaviour Dufa.Pusher

  alias Dufa.APNS.Registry
  alias Dufa.APNS.Client

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

  defp stop_and_push(push_message, opts, on_response_callback) do
    with {:ok, client} <- Registry.lookup(:apns_registry, push_message.token) do
      Client.stop(client)
    end
    do_push(push_message, opts, on_response_callback)
  end

  defp do_push(push_message, opts, on_response_callback) do
    :apns_registry
    |> Registry.create(push_message.token, opts)
    |> Client.push(push_message, on_response_callback)
  end
end
