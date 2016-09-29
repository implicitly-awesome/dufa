defmodule Dufa.GCM do
  alias Dufa.GCM.Client

  def push(push_message, opts \\ %{}, on_response_callback \\ nil) do
    Client.push(push_message, opts, on_response_callback)
  end
end
