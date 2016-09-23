defmodule Dufa.GCM.PushMessage do
  @derive [Poison.Encoder]

  @type t :: %__MODULE__{}

  defstruct to: nil,
            registration_ids: [],
            priority: "normal",
            content_available: nil,
            collapse_key: nil,
            data: %{},
            notification: nil
end
