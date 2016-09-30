defmodule Dufa.GCM do
  @moduledoc """
  GCM pusher.
  """

  @behaviour Dufa.Pusher

  @doc """
  Pushes a `push_message` via APNS with provided `opts` options.
  Invokes a `on_response_callback` on a response.
  """
  @spec push(Dufa.GCM.PushMessage.t, Map.t, fun()) :: {:reply, Dufa.GCM.Client.push_result, Map.t}
  def push(push_message, opts \\ %{}, on_response_callback \\ nil) do
    Dufa.GCM.Client.push(push_message, opts, on_response_callback)
  end
end
