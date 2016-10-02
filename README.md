# Dufa

Library for sending push notifications via GCM and APN services.

## Installation

Add necessary dependencies in `mix.exs` file of your project:

```elixir
def deps do
  [
    {:dufa, github: "madeinussr/dufa"},
    {:chatterbox, github: "joedevivo/chatterbox"}
  ]
end
```

Run `mix deps.get` and add Dufa in applications list of the `mix.exs` file:

```elixir
def application do
  [applications: [:dufa]]
end
```

## Quick examples

```elixir
# APNS
alert = %Dufa.APNS.Alert{title: "Title", body: "Body"}

aps = %Dufa.APNS.Aps{alert: alert}

push_message = %Dufa.APNS.PushMessage{token: "device_token", aps: aps, custom_data: %{key: "value"}}

Dufa.APNS.push(push_message)

# GCM
notification = %Dufa.GCM.Notification{title: "Title", body: "Body"}

push_message = %Dufa.GCM.PushMessage{registration_ids: ["your_id"], notification: notification, data: %{key: "value"}}

Dufa.GCM.push(push_message)
```

## APNS

### configuration

The possible `config/config.exs` configuration:

```elixir
config :dufa,
  apns_mode: :dev,
  apns_cert_file: "a/path/to/cert/file.pem",
  apns_key_file: "a/path/to/key/file.pem"
```

_However, you can not to provide such configuration at all and pass all the stuff as options directly into `Dufa.APNS.push/3` function._
_We'll consider this approach below._

### `Dufa.APNS.PushMessage`

```elixir
{
  token: String.t,
  aps: Dufa.APNS.Aps.t,
  custom_data: Map.t
}
```

Where:

* `token` - a recipient device's token
* `aps` - aps structure (see it's structure below)
* `custom_data` - additional data payload (default = `%{}`)

### `Dufa.APNS.Aps`

```elixir
{
  content_available: pos_integer(),
  badge: pos_integer(),
  sound: String.t,
  alert: Dufa.APNS.Alert.t
}
```

Where:

* `content_available` - new content availability indicator
* `badge` - the number to display as the badge of the app icon
* `sound` - the name of a notification's sound
* `alert` - if this property is included, the system displays a standard alert or a banner (see it's structure below)

### `Dufa.APNS.Alert`

```elixir
{
  title: String.t,
  body: String.t
}
```

Where:

* `title` - a title of a notification banner
* `badge` - a body of a notification banner

### `Dufa.APNS.push/3`

This function pushes prepared `Dufa.APNS.PushMessage` via APNS asynchronously.
It can take additional options as well as callback that will be invoked on APNS's response.

The basic usage:

`Dufa.APNS.push(push_message)`

With a callback:

`Dufa.APNS.push(push_message, %{}, fn(_message, response) -> IO.inspect(response) end)`

Callback function should receive two arguments:

* message - the original push message sent (or tried to send)
* response - `Dufa.APNS.Client` response

With options:

`Dufa.APNS.push(push_message, %{cert_file: "path/to/a/cert/file.pem"})`

Possible options are:

* `mode` - a APNS push mode (:dev or :prod)
* `cert_file` - a path to a certificate's file
* `cert` - a certificate itself (binary data)
* `key_file` - a path to RSA key's file
* `key` - RSA key itself (binary data)

If you provided a configuration in `config/config.exs` file earlier, options values have a priority.
Actually, the priorities are:

* `config mode < opts mode`
* `config apns_cert_file < opts cert_file < opts cert`
* `config apns_key_file < opts key_file < opts key`

## GCM

### configuration

The possible `config/config.exs` configuration:

```elixir
config :dufa,
  apns_mode: :dev,
  apns_cert_file: "a/path/to/cert/file.pem",
  apns_key_file: "a/path/to/key/file.pem"
```

_However, you can not to provide such configuration at all and pass all the stuff as options directly into `Dufa.GCM.push/3` function._
_We'll consider this approach below._

### `Dufa.GCM.PushMessage`

```elixir
{
  to: String.t,
  registration_ids: nonempty_list(),
  priority: String.t,
  content_available: boolean(),
  collapse_key: any(),
  data: Map.t,
  notification: Dufa.GCM.Notification.t
}
```

### `Dufa.GCM.Notification`

```elixir
{
  title: String.t,
  body: String.t,
  icon: String.t,
  sound: String.t
}
```

### `Dufa.GCM.push/3`

This function pushes prepared `Dufa.GCM.PushMessage` via GCM service asynchronously.
It can take additional options as well as callback that will be invoked on GCM's response.

The basic usage:

`Dufa.GCM.push(push_message)`

With a callback:

`Dufa.GCM.push(push_message, %{}, fn(_message, response) -> IO.inspect(response) end)`

Callback function should receive two arguments:

* message - the original push message sent (or tried to send)
* response - `Dufa.GCM.Client` response

With options:

`Dufa.GCM.push(push_message, %{cert_file: "path/to/a/cert/file.pem"})`

Possible options are:

* `api_key` - your GCM API key

If you provided a configuration in `config/config.exs` file earlier, options values have a priority.

## LICENSE

    Copyright © 2016 Andrey Chernykh ( andrei.chernykh@gmail.com )

    This work is free. You can redistribute it and/or modify it under the
    terms of the MIT License. See the LICENSE file for more details.
