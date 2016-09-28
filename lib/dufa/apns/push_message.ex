defmodule Dufa.APNS.PushMessage do
  @derive [Poison.Encoder]

  @type t :: %__MODULE__{}

  defstruct token: nil,
            aps: nil,
            custom_data: %{}
end
