defmodule Dufa.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      # provide HTTP2 client from the app configuration
      worker(Dufa.APNS.Registry, [:apns_registry, Dufa.Network.HTTP2.Chatterbox], id: Dufa.APNS.Registry),
      supervisor(Dufa.APNS.Supervisor, []),
      supervisor(Dufa.GCM.Supervisor, [])
    ]

    supervise(children, strategy: :rest_for_one)
  end
end
