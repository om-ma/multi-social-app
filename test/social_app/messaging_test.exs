defmodule SocialApp.MessagingTest do
  use SocialApp.DataCase

  alias SocialApp.Messaging
  alias SocialApp.Accounts

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

  describe "create_dm/2" do
    test "creates a DM between two users" do
      user1 = create_user(%{username: "alice", email: "alice@test.com"})
      user2 = create_user(%{username: "bob", email: "bob@test.com"})

      assert {:ok, conv} = Messaging.create_dm(user1.id, user2.id)
      assert conv.is_group == false
      assert length(conv.members) == 2
    end

    test "returns existing DM if already exists" do
      user1 = create_user(%{username: "alice2", email: "alice2@test.com"})
      user2 = create_user(%{username: "bob2", email: "bob2@test.com"})

      {:ok, conv1} = Messaging.create_dm(user1.id, user2.id)
      {:ok, conv2} = Messaging.create_dm(user1.id, user2.id)

      assert conv1.id == conv2.id
    end
  end

  describe "create_group/3" do
    test "creates a group conversation" do
      user1 = create_user(%{username: "grp1", email: "grp1@test.com"})
      user2 = create_user(%{username: "grp2", email: "grp2@test.com"})
      user3 = create_user(%{username: "grp3", email: "grp3@test.com"})

      assert {:ok, conv} = Messaging.create_group(user1.id, "Test Group", [user2.id, user3.id])
      assert conv.is_group == true
      assert conv.name == "Test Group"
      assert length(conv.members) == 3
    end
  end

  describe "send_message/3" do
    test "creates a message in a conversation" do
      user1 = create_user(%{username: "snd1", email: "snd1@test.com"})
      user2 = create_user(%{username: "snd2", email: "snd2@test.com"})

      {:ok, conv} = Messaging.create_dm(user1.id, user2.id)

      assert {:ok, message} =
               Messaging.send_message(conv.id, user1.id, %{"body" => "Hello!"})

      assert message.body == "Hello!"
      assert message.sender_id == user1.id
      assert message.conversation_id == conv.id
    end

    test "creates a message with media_url" do
      user1 = create_user(%{username: "snd3", email: "snd3@test.com"})
      user2 = create_user(%{username: "snd4", email: "snd4@test.com"})

      {:ok, conv} = Messaging.create_dm(user1.id, user2.id)

      assert {:ok, message} =
               Messaging.send_message(conv.id, user1.id, %{
                 "body" => "Check this",
                 "media_url" => "https://example.com/img.png"
               })

      assert message.media_url == "https://example.com/img.png"
    end
  end

  describe "list_messages/2" do
    test "returns messages for a conversation" do
      user1 = create_user(%{username: "lst1", email: "lst1@test.com"})
      user2 = create_user(%{username: "lst2", email: "lst2@test.com"})

      {:ok, conv} = Messaging.create_dm(user1.id, user2.id)
      Messaging.send_message(conv.id, user1.id, %{"body" => "msg1"})
      Messaging.send_message(conv.id, user2.id, %{"body" => "msg2"})

      messages = Messaging.list_messages(conv.id)
      assert length(messages) == 2
      assert Enum.at(messages, 0).body == "msg1"
      assert Enum.at(messages, 1).body == "msg2"
    end
  end

  describe "list_conversations/1" do
    test "returns conversations for a user" do
      user1 = create_user(%{username: "lcon1", email: "lcon1@test.com"})
      user2 = create_user(%{username: "lcon2", email: "lcon2@test.com"})

      {:ok, conv} = Messaging.create_dm(user1.id, user2.id)
      Messaging.send_message(conv.id, user1.id, %{"body" => "hi"})

      convs = Messaging.list_conversations(user1.id)
      assert length(convs) >= 1
      assert Enum.any?(convs, fn c -> c.id == conv.id end)
    end
  end

  describe "get_conversation!/2" do
    test "returns conversation if user is member" do
      user1 = create_user(%{username: "getc1", email: "getc1@test.com"})
      user2 = create_user(%{username: "getc2", email: "getc2@test.com"})

      {:ok, conv} = Messaging.create_dm(user1.id, user2.id)

      result = Messaging.get_conversation!(conv.id, user1.id)
      assert result.id == conv.id
    end

    test "raises if user is not a member" do
      user1 = create_user(%{username: "getc3", email: "getc3@test.com"})
      user2 = create_user(%{username: "getc4", email: "getc4@test.com"})
      user3 = create_user(%{username: "getc5", email: "getc5@test.com"})

      {:ok, conv} = Messaging.create_dm(user1.id, user2.id)

      assert_raise Ecto.NoResultsError, fn ->
        Messaging.get_conversation!(conv.id, user3.id)
      end
    end
  end

  describe "mark_as_read/2" do
    test "marks unread messages as read" do
      user1 = create_user(%{username: "mark1", email: "mark1@test.com"})
      user2 = create_user(%{username: "mark2", email: "mark2@test.com"})

      {:ok, conv} = Messaging.create_dm(user1.id, user2.id)
      Messaging.send_message(conv.id, user1.id, %{"body" => "hello"})

      assert Messaging.unread_count(user2.id) == 1

      Messaging.mark_as_read(conv.id, user2.id)

      assert Messaging.unread_count(user2.id) == 0
    end
  end

  describe "unread_count/1" do
    test "returns count of unread messages" do
      user1 = create_user(%{username: "ucnt1", email: "ucnt1@test.com"})
      user2 = create_user(%{username: "ucnt2", email: "ucnt2@test.com"})

      {:ok, conv} = Messaging.create_dm(user1.id, user2.id)
      Messaging.send_message(conv.id, user1.id, %{"body" => "msg1"})
      Messaging.send_message(conv.id, user1.id, %{"body" => "msg2"})

      assert Messaging.unread_count(user2.id) == 2
      assert Messaging.unread_count(user1.id) == 0
    end
  end
end
