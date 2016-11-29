defmodule Dufa.APNS.Supervisor do
  @moduledoc """
  APNS supervisor. Supervises:
  * Dufa.APNS.Client
  """

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

  @spec start_client(Dufa.Network.HTTP2.Client.t, String.t, map()) :: Supervisor.on_start_child
  def start_client(http2_client, device_token, opts) do
    Supervisor.start_child(@name, [http2_client, device_token, SSLConfig.new(opts)])
  end

  @spec stop_client(pid()) :: :ok | {:error, error} when error: :not_found | :simple_one_for_one
  def stop_client(client), do: Supervisor.terminate_child(@name, client)

  @spec clients() :: list()
  def clients, do: Supervisor.which_children(@name)

  @spec stop() :: :ok
  def stop, do: Supervisor.stop(@name)
end
