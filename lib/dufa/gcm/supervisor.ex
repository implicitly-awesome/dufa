defmodule Dufa.GCM.Supervisor do
  @moduledoc """
  GCM supervisor. Supervises:
  * Dufa.GCM.Client
  """

  use Supervisor

  @name Dufa.GCM.Supervisor

  def name, do: @name

  def start_link, do: Supervisor.start_link(__MODULE__, :ok, name: @name)

  def init(:ok) do
    children = [
      worker(Dufa.GCM.Client, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  @spec start_client() :: Supervisor.on_start_child
  def start_client do
    Supervisor.start_child(@name, [])
  end

  @spec stop_client(pid()) :: :ok | {:error, error} when error: :not_found | :simple_one_for_one
  def stop_client(client), do: Supervisor.terminate_child(@name, client)

  @spec clients() :: list()
  def clients, do: Supervisor.which_children(@name)

  @spec stop() :: :ok
  def stop, do: Supervisor.stop(@name)
end
