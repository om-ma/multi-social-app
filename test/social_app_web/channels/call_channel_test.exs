defmodule SocialAppWeb.CallChannelTest do
  use SocialAppWeb.ChannelCase

  alias SocialApp.Accounts
  alias SocialApp.Calls

  defp create_user(attrs) do
    {:ok, user} =
      Accounts.register_user(
        Map.merge(
          %{
            username: "user_#{System.unique_integer([:positive])}",
            email: "user_#{System.unique_integer([:positive])}@test.com",
            password: "password123",
            display_name: "Test User"
          },
          attrs
        )
      )

    user
  end

  setup do
    caller =
      create_user(%{username: "callch1", email: "callch1@test.com", display_name: "Caller"})

    receiver =
      create_user(%{username: "callch2", email: "callch2@test.com", display_name: "Receiver"})

    {:ok, call} =
      Calls.create_call(%{
        caller_id: caller.id,
        receiver_id: receiver.id,
        call_type: "video"
      })

    {:ok, _, caller_socket} =
      SocialAppWeb.UserSocket
      |> socket("user_socket:#{caller.id}", %{user_id: caller.id})
      |> subscribe_and_join(SocialAppWeb.CallChannel, "call:#{call.id}")

    %{
      caller_socket: caller_socket,
      caller: caller,
      receiver: receiver,
      call: call
    }
  end

  test "caller joins call channel successfully", %{caller_socket: socket} do
    assert socket.assigns.call_id
  end

  test "receiver joins call channel successfully", %{receiver: receiver, call: call} do
    {:ok, _, socket} =
      SocialAppWeb.UserSocket
      |> socket("user_socket:#{receiver.id}", %{user_id: receiver.id})
      |> subscribe_and_join(SocialAppWeb.CallChannel, "call:#{call.id}")

    assert socket.assigns.call_id == call.id
  end

  test "non-participant cannot join call channel", %{call: call} do
    outsider =
      create_user(%{username: "outsider", email: "outsider@test.com", display_name: "Outsider"})

    assert {:error, %{reason: "unauthorized"}} =
             SocialAppWeb.UserSocket
             |> socket("user_socket:#{outsider.id}", %{user_id: outsider.id})
             |> subscribe_and_join(SocialAppWeb.CallChannel, "call:#{call.id}")
  end

  test "join fails for non-existent call" do
    user = create_user(%{username: "noone", email: "noone@test.com"})

    assert {:error, %{reason: "not_found"}} =
             SocialAppWeb.UserSocket
             |> socket("user_socket:#{user.id}", %{user_id: user.id})
             |> subscribe_and_join(SocialAppWeb.CallChannel, "call:0")
  end

  test "relays offer", %{caller_socket: socket} do
    push(socket, "offer", %{"sdp" => "{\"type\":\"offer\",\"sdp\":\"v=0...\"}"})
    assert_broadcast "offer", %{sdp: _, from: _}
  end

  test "relays answer", %{caller_socket: socket} do
    push(socket, "answer", %{"sdp" => "{\"type\":\"answer\",\"sdp\":\"v=0...\"}"})
    assert_broadcast "answer", %{sdp: _, from: _}
  end

  test "relays ice_candidate", %{caller_socket: socket} do
    push(socket, "ice_candidate", %{"candidate" => "{\"candidate\":\"a]...\"}"})
    assert_broadcast "ice_candidate", %{candidate: _, from: _}
  end

  test "handles call_end", %{caller_socket: socket} do
    push(socket, "call_end", %{})
    assert_broadcast "call_ended", %{ended_by: _}
  end

  test "handles call_decline", %{caller_socket: socket} do
    push(socket, "call_decline", %{})
    assert_broadcast "call_declined", %{declined_by: _}
  end
end
