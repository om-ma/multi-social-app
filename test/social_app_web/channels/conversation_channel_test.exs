defmodule SocialAppWeb.ConversationChannelTest do
  use SocialAppWeb.ChannelCase

  alias SocialApp.Accounts
  alias SocialApp.Messaging

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
    user1 =
      create_user(%{username: "chan1", email: "chan1@test.com", display_name: "ChannelUser1"})

    user2 =
      create_user(%{username: "chan2", email: "chan2@test.com", display_name: "ChannelUser2"})

    {:ok, conv} = Messaging.create_dm(user1.id, user2.id)

    {:ok, _, socket} =
      SocialAppWeb.UserSocket
      |> socket("user_socket:#{user1.id}", %{user_id: user1.id})
      |> subscribe_and_join(SocialAppWeb.ConversationChannel, "conversation:#{conv.id}")

    %{socket: socket, user1: user1, user2: user2, conversation: conv}
  end

  test "joins conversation successfully", %{socket: socket} do
    assert socket.assigns.conversation_id
  end

  test "rejects join for non-member" do
    user3 = create_user(%{username: "chan3", email: "chan3@test.com"})

    user1 = create_user(%{username: "chan4", email: "chan4@test.com"})
    user2 = create_user(%{username: "chan5", email: "chan5@test.com"})
    {:ok, conv} = Messaging.create_dm(user1.id, user2.id)

    assert {:error, %{reason: "unauthorized"}} =
             SocialAppWeb.UserSocket
             |> socket("user_socket:#{user3.id}", %{user_id: user3.id})
             |> subscribe_and_join(
               SocialAppWeb.ConversationChannel,
               "conversation:#{conv.id}"
             )
  end

  test "handles new_message", %{socket: socket} do
    ref = push(socket, "new_message", %{"body" => "Hello channel!"})
    assert_reply ref, :ok
    assert_broadcast "new_message", %{body: "Hello channel!"}
  end

  test "handles typing", %{socket: socket} do
    push(socket, "typing", %{})
    assert_broadcast "typing", %{user_id: _}
  end

  test "handles stop_typing", %{socket: socket} do
    push(socket, "stop_typing", %{})
    assert_broadcast "stop_typing", %{user_id: _}
  end
end
