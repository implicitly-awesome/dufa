defmodule Dufa.GCM.PushMessage do
  @derive [Poison.Encoder]

  @type t :: %__MODULE__{to: String.t,
                         registration_ids: nonempty_list(),
                         priority: String.t,
                         content_available: boolean(),
                         collapse_key: any(),
                         data: map(),
                         notification: Dufa.GCM.Notification.t}

  defstruct to: nil,
            registration_ids: [],
            priority: "normal",
            content_available: nil,
            collapse_key: nil,
            data: %{},
            notification: nil
end
