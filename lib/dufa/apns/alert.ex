defmodule Dufa.APNS.Alert do
  @derive [Poison.Encoder]

  @enforce_keys [:title]

  @type t :: %__MODULE__{title: String.t, body: String.t}

  defstruct [:title, :body]
end
