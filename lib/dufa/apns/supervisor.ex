defmodule Dufa.APNS.Supervisor do
  use Supervisor

  @name Dufa.APNS.Supervisor

  def name, do: @name

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def start_client do
    Supervisor.start_child(@name, [])
  end

  def stop_client(client) do
    Supervisor.terminate_child(@name, client)
  end

  def clients do
    Supervisor.which_children(@name)
  end

  def stop, do: Supervisor.stop(@name)

  def init(:ok) do
    children = [
      worker(Dufa.APNS.Client, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
