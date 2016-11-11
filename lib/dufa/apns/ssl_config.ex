defmodule Dufa.APNS.SSLConfig do
  @moduledoc """
  Defines APNS SSL configuration structure and provides a configuration's constructor.
  """

  defstruct ~w(mode cert key)a

  @enforce_keys [:mode]

  @type t :: %__MODULE__{mode: atom() | String.t,
                         cert: binary(),
                         key: binary()}

  @spec config_mode() :: atom() | String.t | nil
  defp config_mode,      do: Application.get_env(:dufa, :apns_mode)

  @spec config_cert_file() :: atom() | String.t | nil
  defp config_cert_file, do: Application.get_env(:dufa, :apns_cert_file)

  @spec config_key_file() :: atom() | String.t | nil
  defp config_key_file,  do: Application.get_env(:dufa, :apns_key_file)

  @doc """
  Creates SSL configuration with given `args` arguments.
  """
  @spec new(map()) :: __MODULE__.t
  def new(args \\ %{}) do
    mode = Map.get(args, :mode) || config_mode
    cert = Map.get(args, :cert) || cert(config_cert_file)
    key =  Map.get(args, :key)  || key(config_key_file)

    %__MODULE__{
      mode: mode,
      cert: cert,
      key:  key
    }
  end

  @doc """
  Extracts a certificate from the file by given `file_path`.
  """
  @spec cert(String.t) :: binary()
  def cert(file_path) when is_binary(file_path) do
    file_path |> read_file |> decode_file(:cert)
  end
  def cert(_), do: nil

  @doc """
  Extracts a RSA key from the file by given `file_path`.
  """
  @spec key(String.t) :: binary()
  def key(file_path) when is_binary(file_path) do
    file_path |> read_file |> decode_file(:key)
  end
  def key(_), do: nil

  @doc """
  Reads a content of the file by given `file_path`.
  """
  @spec read_file(String.t) :: String.t | nil
  def read_file(file_path) when is_binary(file_path) do
    with true <- :filelib.is_file(file_path),
         full_file_path <- Path.expand(file_path),
         {:ok, content} <- File.read(full_file_path) do
           content
         else
           _ -> nil
         end
  end

  @doc """
  Decodes a `file_content` depending on given content's `type`.
  """
  @spec decode_file(String.t, :cert | :key) :: binary() | nil
  def decode_file(file_content, type) when is_binary(file_content) and is_atom(type) do
    try do
      case type do
        :cert -> fetch_cert(:public_key.pem_decode(file_content))
        :key -> fetch_key(:public_key.pem_decode(file_content))
        _ -> nil
      end
    rescue
      _ -> nil
    end
  end
  def decode_file(_file_content, _type), do: nil

  @spec fetch_cert(list()) :: binary() | nil
  defp fetch_cert([]), do: nil
  defp fetch_cert([{:Certificate, cert, _} | _tail]), do: cert
  defp fetch_cert([_head | tail]), do: fetch_cert(tail)
  defp fetch_cert(_), do: nil

  @spec fetch_key(list()) :: binary() | nil
  defp fetch_key([]), do: nil
  defp fetch_key([{:RSAPrivateKey, key, _} | _tail]), do: {:RSAPrivateKey, key}
  defp fetch_key([_head | tail]), do: fetch_key(tail)
  defp fetch_key(_), do: nil
end
