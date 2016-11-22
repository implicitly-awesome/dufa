defmodule Dufa.APNS.Registry do
  @moduledoc """
  APNS clients registry. Stores connections (per device token) opened by
  correspond clients (pids).
  """

  use GenServer

  def start_link(name, http2_client) do
    GenServer.start_link(__MODULE__, {name, http2_client}, name: name)
  end

  @spec init({String.t | atom(), any()}) :: {:ok, {atom() | pos_integer(), map()}}
  def init({table, http2_client}) do
    tokens = :ets.new(table, [:named_table, :set, read_concurrency: true])
    refs = %{}
    {:ok, {http2_client, tokens, refs}}
  end

  @doc """
  Looks up for APNS.Client's pid, stored in the `registry`, by a device's `token`.
  """
  @spec lookup(atom() | pos_integer(), String.t) :: {:ok, pid()} | :error
  def lookup(registry, token) do
    case :ets.lookup(registry, token) do
      [{^token, pid}] -> {:ok, pid}
      _ -> :error
    end
  end

  @doc """
  Looks up for APNS.Client's pid, stored in the `registry`, by a device's `token` and return it or create it, either.
  """
  @spec create(pid(), String.t, map()) :: {:reply, pid(), tuple()}
  def create(registry, token, opts \\ %{}) do
    GenServer.call(registry, {:create, token, opts})
  end

  @doc """
  Stops the `registry`.
  """
  @spec stop(pid) :: :ok
  def stop(registry), do: GenServer.stop(registry)

  def handle_call({:create, token, opts}, _from, {http2_client, tokens, refs}) do
    case lookup(tokens, token) do
      {:ok, pid} ->
        {:reply, pid, {http2_client, tokens, refs}}
      :error ->
        {:ok, pid} = Dufa.APNS.Supervisor.start_client(http2_client, token, opts)
        ref = Process.monitor(pid)
        refs = Map.put(refs, ref, token)
        :ets.insert(tokens, {token, pid})
        {:reply, pid, {http2_client, tokens, refs}}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {http2_client, tokens, refs}) do
    {token, refs} = Map.pop(refs, ref)
    :ets.delete(tokens, token)
    {:noreply, {http2_client, tokens, refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
