defmodule Dufa.APNS.Aps do
  @derive [Poison.Encoder]

  @type t :: %__MODULE__{}

  defstruct content_available: nil,
            badge: nil,
            sound: nil,
            alert: nil
end
