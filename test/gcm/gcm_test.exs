defmodule GCMTest do
  use ExUnit.Case, async: true

  import Mock
  import Dufa.GCM

  alias Application
  alias Dufa.GCM.Notification
  alias Dufa.GCM.PushMessage

  @uri "https://gcm-http.googleapis.com"
  @path "/gcm/send"

  @invalid_api_key "invalid_api_key"

  @registered_reg_id "registered_reg_id"
  @unregistered_reg_id "unregistered_reg_id"

  @successful_response %HTTPoison.Response{
    status_code: 200,
    body: ~S({"results":["everything is fine"]})
  }
  @errors_response %HTTPoison.Response{
    status_code: 200,
    body: ~S({"results":[{"error":"oops"}, {"error":"oops2"}]})
  }
  @unhandled_response %HTTPoison.Response{status_code: 777}

  setup do
    notification = %Notification{title: "Title", body: "This is the body"}
    push_message = %PushMessage{
      registration_ids: [@registered_reg_id],
      notification: notification,
      data: %{}
    }

    %{notification: notification, push_message: push_message}
  end

  test_with_mock "push/2: gets gcm_api_key from the config",
                 %{push_message: push_message},
                 HTTPoison,
                 [],
                 [post: fn(_, _, _) -> {:ok, @successful_response} end] do
    valid_headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "key=#{Application.get_env(:dufa, :gcm_api_key)}"}
    ]
    push(push_message)

    assert called HTTPoison.post("#{@uri}#{@path}", Poison.encode!(push_message), valid_headers)
  end

  test_with_mock "push/2: gets gcm_api_key from the opts",
                 %{push_message: push_message},
                 HTTPoison,
                 [],
                 [post: fn(_, _, _) -> {:ok, @successful_response} end] do
    valid_headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "key=qwerty"}
    ]
    push(push_message, api_key: "qwerty")

    assert called HTTPoison.post("#{@uri}#{@path}", Poison.encode!(push_message), valid_headers)
  end

  test "push/2: returns an error if gcm_api_key is nil", %{push_message: push_message} do
    assert push(push_message, api_key: nil) == {:error, :undefined_api_key}
  end

  test_with_mock "push/2: returns error with unknown response status",
                 %{push_message: push_message},
                 HTTPoison,
                 [],
                 [post: fn(_, _, _) -> {:ok, @unhandled_response} end] do
    result = push(push_message)
    assert result == {:error, :unhandled_error}
  end

  test "push/2: returns error with invalid gcm_api_key",
                 %{push_message: push_message} do
    result = push(push_message, api_key: "qwerty")
    assert result == {:error, :unauthorized}
  end

  test_with_mock "push/2: returns errors list for errors response (status 200 though)",
                 %{push_message: push_message},
                 HTTPoison,
                 [],
                 [post: fn(_, _, _) -> {:ok, @errors_response} end] do
    result = push(push_message)
    assert result == {:error, ["oops", "oops2"]}
  end

  test_with_mock "push/2: returns error with failed request",
                 %{push_message: push_message},
                 HTTPoison,
                 [],
                 [post: fn(_, _, _) -> {:error, "error reason"} end] do
    result = push(push_message)
    assert result == {:error, :unhandled_error}
  end
end
