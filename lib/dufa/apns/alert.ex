defmodule Dufa.APNS.Alert do
  @derive [Poison.Encoder]

  @type t :: %__MODULE__{}

  defstruct [:title, :body]
end
