defmodule Dufa.Network.HTTP2.Client do
  @moduledoc """
  Behaviour that defines base callback need to implement by http2 client.
  """
  @type t :: __MODULE__

  @callback uri(atom(), atom()) :: list()

  @callback open_socket(atom(), map(), pos_integer()) :: {:ok, pid()} |
                                                         {:error, :open_socket, :timeout} |
                                                         {:error, :ssl_config, :certificate_missed} |
                                                         {:error, :ssl_config, :rsa_key_missed}

  @callback send_request(pid(), list(), String.t) :: {:ok, pid()} | any()

  @callback get_response(pid(), pid()) :: {:ok, {String.t, String.t}} | any()
end
