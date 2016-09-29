defmodule Dufa.GCM.Notification do
  @derive [Poison.Encoder]

  @enforce_keys [:title]

  @type t :: %__MODULE__{title: String.t,
                         body: String.t,
                         icon: String.t,
                         sound: String.t}

  defstruct [:title, :body, :icon, :sound]
end
