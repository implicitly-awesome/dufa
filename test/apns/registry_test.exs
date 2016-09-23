defmodule APNS.RegistryTest do
  use ExUnit.Case, async: false

  setup context do
    Enum.each(Dufa.APNS.Supervisor.clients, fn {_, client, _, _} ->
      Dufa.APNS.Supervisor.stop_client(client)
    end)
    {:ok, _} = Dufa.APNS.Registry.start_link(context.test)
    {:ok, registry: context.test, device_token: "token"}
  end

  test "creates client", %{registry: registry, device_token: token} do
    assert Dufa.APNS.Registry.lookup(registry, token) == :error

    Dufa.APNS.Registry.create(registry, token)
    assert {:ok, client} = Dufa.APNS.Registry.lookup(registry, token)

    assert Dufa.APNS.Client.ping(client, "hello") == {:pong, "hello"}
  end

  test "removes clients on exit", %{registry: registry, device_token: token} do
    assert Dufa.APNS.Registry.lookup(registry, token) == :error
    client = Dufa.APNS.Registry.create(registry, token)
    Dufa.APNS.Supervisor.stop_client(client)

    assert Dufa.APNS.Registry.lookup(registry, token) == :error
  end

  test "removes clients on crash", %{registry: registry, device_token: token} do
    client = Dufa.APNS.Registry.create(registry, token)

    Process.exit(client, :shutdown)

    ref = Process.monitor(client)
    assert_receive {:DOWN, ^ref, _, _, _}

    _ = Dufa.APNS.Registry.create(registry, "another_token")
    assert Dufa.APNS.Registry.lookup(registry, token) == :error
  end
end
