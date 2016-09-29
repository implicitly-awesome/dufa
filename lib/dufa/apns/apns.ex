defmodule Dufa.APNS do
  @behaviour Dufa.Pusher

  alias Dufa.APNS.Registry
  alias Dufa.APNS.Client

  def push(push_message, opts \\ %{}, on_response_callback \\ nil) do
    :apns_registry
    |> Registry.create(push_message.token, opts)
    |> Client.push(push_message, on_response_callback)
  end
end
