defmodule Dufa.APNS.SSLConfig do
  defstruct ~w(mode cert cert_file key key_file)a

  @type t :: __MODULE__

  defp config_mode, do: Application.get_env(:dufa, :apns_mode)
  defp config_cert, do: Application.get_env(:dufa, :apns_cert)
  defp config_key,  do: Application.get_env(:dufa, :apns_key)

  def new(args) do
    %__MODULE__{
      mode: (Keyword.get(args, :mode) || config_mode),
      cert: (Keyword.get(args, :cert) || cert(config_cert)),
      key:  (Keyword.get(args, :key)  || key(config_key))
    }
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
      :cert ->
        # IO.inspect :public_key.pem_decode(file)
        case :public_key.pem_decode(file) do
          [{:Certificate, cert, _}] -> cert
          [{:Certificate, cert, _}, {:RSAPrivateKey, _, _}] -> cert
          _ -> nil
        end
      :key ->
        case :public_key.pem_decode(file) do
         [{:RSAPrivateKey, key, _}] -> key
         [{:Certificate, _, _}, {:RSAPrivateKey, key, _}] -> key
         _ -> nil
        end
      _ ->
        nil
    end
  end
end
