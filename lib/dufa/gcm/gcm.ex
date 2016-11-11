defmodule Dufa.GCM do
  @moduledoc """
  GCM pusher.
  """

  @behaviour Dufa.Pusher

  @doc """
  Pushes a `push_message` via GCM with provided `opts` options.
  Invokes a `on_response_callback` on a response.
  """
  @spec push(Dufa.GCM.PushMessage.t, map(), fun() | nil) :: {:noreply, map()}
  def push(push_message, opts \\ %{}, on_response_callback \\ nil) do
    {:ok, client} = Dufa.GCM.Supervisor.start_client
    Dufa.GCM.Client.push(client, push_message, opts, on_response_callback)
  end
end
