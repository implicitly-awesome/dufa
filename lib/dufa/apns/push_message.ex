defmodule Dufa.APNS.PushMessage do
  @derive [Poison.Encoder]

  @enforce_keys [:token]

  @type t :: %__MODULE__{token: String.t, aps: Dufa.APNS.Aps.t, custom_data: Map.t}

  defstruct token: nil,
            aps: nil,
            custom_data: %{}
end
