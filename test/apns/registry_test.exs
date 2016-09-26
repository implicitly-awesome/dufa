defmodule APNS.RegistryTest do
  use ExUnit.Case, async: false

  alias Dufa.APNS.SSLConfig

  setup context do
    {:ok, _} = Dufa.APNS.Registry.start_link(context.test)
    {:ok, registry: context.test, device_token: "device_token"}
  end

  test "creates client", %{registry: registry, device_token: token} do
    assert Dufa.APNS.Registry.lookup(registry, token) == :error

    Dufa.APNS.Registry.create(registry, token)
    assert {:ok, client} = Dufa.APNS.Registry.lookup(registry, token)

    assert Dufa.APNS.Client.ping(client) == {:pong, ["device_token", %SSLConfig{}]}
  end

  test "removes clients on exit", %{registry: registry, device_token: token} do
    assert Dufa.APNS.Registry.lookup(registry, token) == :error
    client = Dufa.APNS.Registry.create(registry, token)

    ref = Process.monitor(client)
    Dufa.APNS.Supervisor.stop_client(client)
    assert_receive {:DOWN, ^ref, _, _, _}

    assert Dufa.APNS.Registry.lookup(registry, token) == :error
  end

  test "removes clients on crash", %{registry: registry, device_token: token} do
    client = Dufa.APNS.Registry.create(registry, token)

    ref = Process.monitor(client)
    Process.exit(client, :shutdown)
    assert_receive {:DOWN, ^ref, _, _, _}

    _ = Dufa.APNS.Registry.create(registry, "another_token")
    assert Dufa.APNS.Registry.lookup(registry, token) == :error
  end
end
