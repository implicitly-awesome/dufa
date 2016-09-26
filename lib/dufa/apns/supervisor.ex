defmodule Dufa.APNS.Supervisor do
  use Supervisor

  @name Dufa.APNS.Supervisor

  alias Dufa.APNS.SSLConfig

  def name, do: @name

  def start_link, do: Supervisor.start_link(__MODULE__, :ok, name: @name)

  def init(:ok) do
    children = [
      worker(Dufa.APNS.Client, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  def start_client(device_token, opts) do
    Supervisor.start_child(@name, [device_token, SSLConfig.new(opts)])
  end

  def stop_client(client), do: Supervisor.terminate_child(@name, client)

  def clients, do: Supervisor.which_children(@name)

  def stop, do: Supervisor.stop(@name)
end
