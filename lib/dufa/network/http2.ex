defmodule Dufa.Network.HTTP2 do
  @moduledoc """
  Exposes the API for HTTP2 interaction.
  """

  defmodule Connection do
    @moduledoc """
    Defines the structure of a HTTP2 connection.
    """

    @derive [Poison.Encoder]

    @type t :: %__MODULE__{client: any(),
                           provider: atom(),
                           socket: pid(),
                           config: map()}

    defstruct ~w(client provider socket config)a
  end

  alias Dufa.Network.HTTP2.Connection

  @doc "Opens and returns a connection to the `provider` with specified `config` and the `client` that handles the connection"
  @spec connect(Dufa.Network.HTTP2.Client.t, atom(), Dufa.APNS.SSLConfig.t) ::
    {:ok, Dufa.Network.HTTP2.Connection.t} | {:error, any()}
  def connect(client, provider, config) do
    case client.open_socket(provider, config, 0) do
      {:ok, socket} ->
        connection = %Connection{
          client: client,
          provider: provider,
          socket: socket,
          config: config
        }
        {:ok, connection}
      error ->
        error
    end
  end

  @doc "Sends a request via `connection` with `headers` and `paylaod`"
  def send_request(%{client: client, socket: socket} = _connection, headers, payload) do
    client.send_request(socket, headers, payload)
  end

  @doc "Try to get a response from the `connection`'s `stream`"
  def get_response(%{client: client, socket: socket} = _connection, stream) do
    client.get_response(socket, stream)
  end
end
