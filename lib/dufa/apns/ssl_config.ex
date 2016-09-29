defmodule Dufa.APNS.SSLConfig do
  defstruct ~w(mode cert key)a

  @enforce_keys [:mode, :cert, :key]

  @type t :: %__MODULE__{mode: atom(), cert: binary(), key: binary()}

  defp config_mode,      do: Application.get_env(:dufa, :apns_mode)
  defp config_cert_file, do: Application.get_env(:dufa, :apns_cert_file)
  defp config_key_file,  do: Application.get_env(:dufa, :apns_key_file)

  def new(args \\ %{}) do
    conf = %__MODULE__{
      mode: (Map.get(args, :mode) || config_mode),
      cert: (Map.get(args, :cert) || cert(config_cert_file)),
      key:  (Map.get(args, :key)  || key(config_key_file)),
    }

    conf
  end

  def cert(file) when is_binary(file) do
    file |> read_file |> decode_file(:cert)
  end
  def cert(_), do: nil

  def key(file) when is_binary(file) do
    file |> read_file |> decode_file(:key)
  end
  def key(_), do: nil

  def read_file(file_path) when is_binary(file_path) do
    with true <- :filelib.is_file(file_path),
         full_file_path <- Path.expand(file_path),
         {:ok, content} <- File.read(full_file_path) do
           content
         else
           _ -> nil
         end
  end

  def decode_file(file, type) when is_binary(file) and is_atom(type) do
    case type do
      :cert -> fetch_cert(:public_key.pem_decode(file))
      :key -> fetch_key(:public_key.pem_decode(file))
      _ -> nil
    end
  end

  defp fetch_cert([]), do: nil
  defp fetch_cert([{:Certificate, cert, _} | _tail]), do: cert
  defp fetch_cert([_head | tail]), do: fetch_cert(tail)
  defp fetch_cert(_), do: nil

  defp fetch_key([]), do: nil
  defp fetch_key([{:RSAPrivateKey, key, _} | _tail]), do: {:RSAPrivateKey, key}
  defp fetch_key([_head | tail]), do: fetch_key(tail)
  defp fetch_key(_), do: nil
end
