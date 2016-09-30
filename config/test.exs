use Mix.Config

config :dufa,
       gcm_api_key: "your_api_key",
       apns_mode: :dev,
       apns_cert_file: Path.expand("test/fixtures/test_apns_cert.pem"),
       apns_key_file: Path.expand("test/fixtures/test_apns_key.pem")

# none backend for Logger in tests if we don't want to see Logger spamming the output during tests run
config :logger,
       backends: []
