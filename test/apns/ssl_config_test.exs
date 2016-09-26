defmodule APNS.SSLConfigTest do
  use ExUnit.Case, async: true

  alias Dufa.APNS.SSLConfig

  setup do
    file_path = Path.expand("test/fixtures/file")
    cert_file_path = Path.expand("test/fixtures/test_apns_cert.pem")
    key_file_path = Path.expand("test/fixtures/test_apns_key.pem")
    {:ok, %{file_path: file_path, cert_file_path: cert_file_path, key_file_path: key_file_path}}
  end

  test "read_file/1: finds a file and reads the file's content if the file exists", %{file_path: file_path} do
    content = SSLConfig.read_file(file_path)
    assert String.trim(content) == "this is a file content"
  end

  test "read_file/1: returns nil unless a file exists", %{file_path: file_path} do
    refute SSLConfig.read_file(file_path <> "oops")
  end

  test "decode_file/2: returns nil unless decoded file type neither :cert nor :key" do
    refute SSLConfig.decode_file("file", :unknown)
  end

  test "decode_file/2: returns nil for a file's content that not is pem" do
    result = "not pem cert content" |> SSLConfig.decode_file(:cert)
    refute result
  end

  test "decode_file/2: returns pem for a file's content that is pem", %{cert_file_path: cert_file_path} do
    result =
      cert_file_path
      |> SSLConfig.read_file
      |> SSLConfig.decode_file(:cert)

    assert result
  end

  test "decode_file/2: returns nil for a file's content that not is key" do
    result = "not key content" |> SSLConfig.decode_file(:key)
    refute result
  end

  test "decode_file/2: returns key for a file's content that is key", %{key_file_path: key_file_path} do
    result =
      key_file_path
      |> SSLConfig.read_file
      |> SSLConfig.decode_file(:key)

    assert result
  end

end
