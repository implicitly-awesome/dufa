defmodule Dufa.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      worker(Dufa.APNS.Registry, [:apns_registry], id: :apns_registry),
      supervisor(Dufa.APNS.Supervisor, [])
    ]

    supervise(children, strategy: :rest_for_one)
  end
end
