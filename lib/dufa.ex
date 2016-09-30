defmodule Dufa do
  @moduledoc """
  Library for sending push notifications with GCM and APN services.

  ## Example
      # APNS
      alert = %Dufa.APNS.Alert{title: "Title", body: "Body"}
      aps = %Dufa.APNS.Aps{content_available: true,
                           badge: 1,
                           sound: "sound",
                           alert: alert}
      push_message = %Dufa.APNS.PushMessage{token: "device_token",
                                            aps: aps,
                                            custom_data: %{key: "value"}}
      opts = %{}
      response_callback = fn(_push_message, response) -> IO.inspect(response) end

      Dufa.APNS.push(push_message, opts, response_callback)

      # GCM
      notification = %Dufa.GCM.Notification{title: "Title",
                                            body: "Body",
                                            icon: "icon",
                                            sound: "sound"}
      push_message = %Dufa.GCM.PushMessage{registration_ids: ["your_id"],
                                           notification: notification,
                                           data: %{key: "value"}}
      opts = %{}
      response_callback = fn(_push_message, response) -> IO.inspect(response) end

      Dufa.GCM.push(push_message, opts, response_callback)
  """

  use Application

  def start(_type, _args), do: Dufa.Supervisor.start_link
end
