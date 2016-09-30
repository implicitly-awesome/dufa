defmodule Dufa.GCM do
  @behaviour Dufa.Pusher

  @spec push(Dufa.GCM.PushMessage.t, Map.t, fun()) :: {:reply, Dufa.GCM.Client.push_result, Map.t}
  def push(push_message, opts \\ %{}, on_response_callback \\ nil) do
    Dufa.GCM.Client.push(push_message, opts, on_response_callback)
  end
end
