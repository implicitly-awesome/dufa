defmodule APNS.RegistryTest do
  use ExUnit.Case, async: false

  defmodule TestHTTP2Client do
    @behaviour Dufa.Network.HTTP2.Client

    def uri(:apns, :prod), do: to_char_list("apns_prod_uri")
    def uri(:apns, :dev), do: to_char_list("apns_dev_uri")

    def open_socket(_, _, _), do: {:ok, nil}

    def send_request(_, _, _), do: :ok

    def get_response(_, _), do: :ok
  end

  setup context do
    {:ok, _} = Dufa.APNS.Registry.start_link(context.test, TestHTTP2Client)
    {:ok, registry: context.test, token: "device_token"}
  end

  test "creates client", %{registry: registry, token: token} do
    assert Dufa.APNS.Registry.lookup(registry, token) == :error

    Dufa.APNS.Registry.create(registry, token)
    assert {:ok, _client} = Dufa.APNS.Registry.lookup(registry, token)
  end

  test "removes clients on crash", %{registry: registry, token: token} do
    client = Dufa.APNS.Registry.create(registry, token)

    ref = Process.monitor(client)
    Process.exit(client, :shutdown)
    assert_receive {:DOWN, ^ref, _, _, _}

    _ = Dufa.APNS.Registry.create(registry, "another_token")
    assert Dufa.APNS.Registry.lookup(registry, token) == :error
    assert {:ok, _client} = Dufa.APNS.Registry.lookup(registry, "another_token")
  end

  test "removes clients on exit", %{registry: registry, token: token} do
    assert Dufa.APNS.Registry.lookup(registry, token) == :error
    client = Dufa.APNS.Registry.create(registry, token)

    ref = Process.monitor(client)
    Dufa.APNS.Supervisor.stop_client(client)
    assert_receive {:DOWN, ^ref, _, _, _}

    assert Dufa.APNS.Registry.lookup(registry, token) == :error
  end
end
