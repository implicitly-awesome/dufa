# Dufa

Library for sending push notifications with GCM and APN services.

## Under construction...

Currently GCM pushes were implemented.

```elixir
notification = %Dufa.GCM.Notification{title: "Title", body: "This is a body"}
push_message = %Dufa.GCM.PushMessage{
  registration_ids: ["your_reg_id"],
  notification: notification},
  data: %{key: "value"}
}

Dufa.GCM.push(push_message)
```

See tests and module docs, functions specs for details.
