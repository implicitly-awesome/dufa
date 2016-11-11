defmodule Dufa.Pusher do
  @callback push(Dufa.APNS.PushMessage.t | Dufa.GCM.PushMessage.t,
                 map(),
                 (Dufa.APNS.PushMessage.t | Dufa.GCM.PushMessage.t, any() -> any() | nil)) :: {:noreply, map()}
end
