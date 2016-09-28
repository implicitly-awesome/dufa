use Mix.Config

config :dufa,
       gcm_api_key: "your_api_key",
       apns_mode: :dev,
       apns_cert_file: "/Users/andreichernykh/Documents/Projects/erlang/elixir/dufa/test/fixtures/test_apns_cert.pem",
       apns_key_file: "/Users/andreichernykh/Documents/Projects/erlang/elixir/dufa/test/fixtures/test_apns_key.pem"

config :logger,
       backends: []
