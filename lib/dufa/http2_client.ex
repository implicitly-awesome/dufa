defmodule Dufa.HTTP2Client do
  @apns_production_api_uri "api.push.apple.com"
  @apns_development_api_uri "api.development.push.apple.com"

  def uri(:apns, :dev), do: to_char_list(@apns_development_api_uri)
  def uri(:apns, :prod), do: to_char_list(@apns_production_api_uri)

  def open_socket(_, _, 3), do: {:error, :open_cosket, :timeout}
  def open_socket(provider, %{cert: nil}, _tries), do: {:error, :ssl_config, "Need to provide a certificate"}
  def open_socket(provider, %{key: nil}, _tries), do: {:error, :ssl_config, "Need to provide RSA key"}
  def open_socket(provider, %{mode: mode, cert: cert, key: key} = ssl_config, tries) do
    case :h2_client.start_link(:https, uri(provider, mode), socket_config({:cert, cert}, {:key, key})) do
      {:ok, socket} -> {:ok, socket}
      _ -> open_socket(provider, ssl_config, tries + 1)
    end
  end
  def open_socket(_, _, _), do: {:error, :ssl_config, "Invalid SSL config"}

  defp socket_config(cert, key) do
    [
      cert,
      key,
      {:password, ''},
      {:packet, 0},
      {:reuseaddr, true},
      {:active, true},
      :binary
    ]
  end

  def send_request(socket, headers, payload) do
    :h2_client.send_request(socket, headers, payload)
  end

  def get_response(socket, stream) do
    :h2_client.get_response(socket, stream)
  end
end
