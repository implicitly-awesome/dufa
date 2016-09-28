defmodule Dufa.APNS do
  alias Dufa.APNS.Registry
  alias Dufa.APNS.Client

  def push(push_message, opts \\ [], on_response_callback \\ nil) do
    Registry.create(:apns_registry, push_message.token, opts)
    |> Client.push(push_message, on_response_callback)
  end
end
