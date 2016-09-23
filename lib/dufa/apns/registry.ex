defmodule Dufa.APNS.Registry do
  use GenServer

  @doc """
  Starts the registry with the given `name`.
  """
  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: name)
  end

  def init(table) do
    tokens = :ets.new(table, [:named_table, :set, read_concurrency: true])
    refs = %{}
    {:ok, {tokens, refs}}
  end

  @doc """
  Looks up for APNS.Client's pid, stored in the `registry`, by a device's `token`.
  """
  def lookup(registry, token) do
    case :ets.lookup(registry, token) do
      [{^token, pid}] -> {:ok, pid}
      [] -> :error
    end
  end

  @doc """
  Looks up for APNS.Client's pid, stored in the `registry`, by a device's `token` and return it or create it, either.
  """
  def create(registry, token) do
    GenServer.call(registry, {:create, token})
  end

  @doc """
  Stops the `registry`.
  """
  def stop(registry), do: GenServer.stop(registry)

  def handle_call({:create, token}, _from, {tokens, refs}) do
    case lookup(tokens, token) do
      {:ok, pid} ->
        {:reply, pid, {tokens, refs}}
      :error ->
        {:ok, pid} = Dufa.APNS.Supervisor.start_client
        ref = Process.monitor(pid)
        refs = Map.put(refs, ref, token)
        :ets.insert(tokens, {token, pid})
        {:reply, pid, {tokens, refs}}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {tokens, refs}) do
    {token, refs} = Map.pop(refs, ref)
    :ets.delete(tokens, token)
    {:noreply, {tokens, refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
