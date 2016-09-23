defmodule Dufa do
  @moduledoc """
  Library for sending push notifications with GCM and APN services.
  """

  use Application

  def start(_type, _args), do: Dufa.Supervisor.start_link
end
