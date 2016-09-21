defmodule Dufa.GCM.Notification do
  @derive [Poison.Encoder]

  @type t :: %__MODULE__{}

  defstruct [:title, :body, :icon, :sound]
end
