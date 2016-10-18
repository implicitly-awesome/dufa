defmodule Dufa.Pusher do
  @callback push(Dufa.APNS.PushMessage.t | Dufa.GCM.PushMessage.t,
                 Map.t,
                 (Dufa.APNS.PushMessage.t | Dufa.GCM.PushMessage.t, any() -> any() | nil)) :: {:noreply, Map.t}
end
