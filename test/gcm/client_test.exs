defmodule GCM.ClientTest do
  use ExUnit.Case, async: false

  import Mock

  alias Dufa.GCM.Client
  alias Dufa.GCM.PushMessage
  alias Dufa.GCM.Notification

  @client_name :gcm_client

  @uri "https://gcm-http.googleapis.com"
  @path "/gcm/send"

  @successful_response %HTTPoison.Response{
    status_code: 200,
    body: ~S({"results":["everything is fine"]})
  }
  @errors_response %HTTPoison.Response{
    status_code: 200,
    body: ~S({"results":[{"error":"oops"}, {"error":"oops2"}]})
  }

  def successful_callback(_push_message, response) do
    assert response == @successful_response.body
  end

  def error_callback(_push_message, response) do
    assert response == {:error, {200, ["oops", "oops2"]}}
  end

  setup do
    registration_id = "your_registration_id"
    notification = %Notification{title: "Title", body: "Body"}
    push_message = %PushMessage{
      registration_ids: [registration_id],
      notification: notification,
      data: %{}
    }

    {:ok, push_message: push_message}
  end

  test "stop/0: stops the client" do
    client = Process.whereis(@client_name)
    Client.stop
    refute Process.alive?(client)
  end

  test_with_mock "push/2: gets gcm_api_key from the config",
                 %{push_message: push_message},
                 HTTPoison,
                 [],
                 [post: fn(_, _, _) -> {:ok, @successful_response} end] do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "key=#{Application.get_env(:dufa, :gcm_api_key)}"}
    ]
    Client.push(push_message)

    assert called HTTPoison.post("#{@uri}#{@path}", Poison.encode!(push_message), headers)
  end

  test_with_mock "push/2: gets gcm_api_key from opts",
                 %{push_message: push_message},
                 HTTPoison,
                 [],
                 [post: fn(_, _, _) -> {:ok, @successful_response} end] do
    api_key = "some_key"
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "key=#{api_key}"}
    ]
    Client.push(push_message, %{api_key: api_key})

    assert called HTTPoison.post("#{@uri}#{@path}", Poison.encode!(push_message), headers)
  end

  test "push/3: sends push notification", %{push_message: push_message} do
    with_mock(HTTPoison, [], [post: fn (_,_,_) -> {:ok, @successful_response} end]) do
      Client.push(push_message)

      headers = [
        {"Content-Type", "application/json"},
        {"Authorization", "key=#{Application.get_env(:dufa, :gcm_api_key)}"}
      ]
      payload = push_message |> Poison.encode!

      assert called HTTPoison.post("#{@uri}#{@path}", payload, headers)
    end
  end

  test "push/3: sends push notification and invokes a callback", %{push_message: push_message} do
    with_mock(HTTPoison, [], [post: fn (_,_,_) -> {:ok, @successful_response} end]) do
      Client.push(push_message, [], &__MODULE__.successful_callback/2)
    end
  end

  test "push/3: handles error response and invoke a callback", %{push_message: push_message} do
    with_mock(HTTPoison, [], [post: fn (_,_,_) -> {:ok, @errors_response} end]) do
      Client.push(push_message, [], &__MODULE__.error_callback/2)
    end
  end
end
