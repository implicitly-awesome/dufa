defmodule APNS.RegistryTest do
  use ExUnit.Case, async: false

  import Mock

  alias Dufa.HTTP2Client

  setup context do
    {:ok, _} = Dufa.APNS.Registry.start_link(context.test)
    {:ok, registry: context.test, device_token: "device_token"}
  end

  test_with_mock "creates client",
                 %{registry: registry, device_token: token},
                 HTTP2Client,
                 [],
                 [open_socket: fn (_, _, _) -> {:ok, nil} end] do
    assert Dufa.APNS.Registry.lookup(registry, token) == :error

    Dufa.APNS.Registry.create(registry, token)
    assert {:ok, _client} = Dufa.APNS.Registry.lookup(registry, token)
  end

  test_with_mock "removes clients on exit",
                 %{registry: registry, device_token: token},
                 HTTP2Client,
                 [],
                 [open_socket: fn (_, _, _) -> {:ok, nil} end] do
    assert Dufa.APNS.Registry.lookup(registry, token) == :error
    client = Dufa.APNS.Registry.create(registry, token)

    ref = Process.monitor(client)
    Dufa.APNS.Supervisor.stop_client(client)
    assert_receive {:DOWN, ^ref, _, _, _}

    assert Dufa.APNS.Registry.lookup(registry, token) == :error
  end

  test_with_mock "removes clients on crash",
                 %{registry: registry, device_token: token},
                 HTTP2Client,
                 [],
                 [open_socket: fn (_, _, _) -> {:ok, nil} end] do
    client = Dufa.APNS.Registry.create(registry, token)

    ref = Process.monitor(client)
    Process.exit(client, :shutdown)
    assert_receive {:DOWN, ^ref, _, _, _}

    _ = Dufa.APNS.Registry.create(registry, "another_token")
    assert Dufa.APNS.Registry.lookup(registry, token) == :error
  end
end
