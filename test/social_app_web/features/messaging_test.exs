defmodule SocialAppWeb.Features.MessagingTest do
  use SocialAppWeb.FeatureCase, async: false

  alias SocialApp.Messaging

  describe "messaging page" do
    test "messages page loads with header", %{session: session} do
      user = create_test_user()

      session
      |> login(user)
      |> assert_has(css("h1", text: "Feed"))
      |> visit("/messages")
      |> assert_has(css("h1", text: "Messages"))
    end

    test "messages page shows empty state when no conversations", %{session: session} do
      user = create_test_user()

      session
      |> login(user)
      |> assert_has(css("h1", text: "Feed"))
      |> visit("/messages")
      |> assert_has(css("p", text: "No conversations yet"))
    end

    test "messages page shows conversation list", %{session: session} do
      user1 = create_test_user(%{"display_name" => "Alice"})
      user2 = create_test_user(%{"display_name" => "Bob"})

      {:ok, conv} = Messaging.create_dm(user1.id, user2.id)
      Messaging.send_message(conv.id, user2.id, %{"body" => "Hey Alice!"})

      session
      |> login(user1)
      |> assert_has(css("h1", text: "Feed"))
      |> visit("/messages")
      |> assert_has(css("h1", text: "Messages"))
      |> assert_has(css("p", text: "Hey Alice!"))
    end

    test "click on a conversation opens chat window", %{session: session} do
      user1 = create_test_user(%{"display_name" => "ChatUser1"})
      user2 = create_test_user(%{"display_name" => "ChatUser2"})

      {:ok, conv} = Messaging.create_dm(user1.id, user2.id)
      Messaging.send_message(conv.id, user2.id, %{"body" => "Hello there!"})

      session
      |> login(user1)
      |> assert_has(css("h1", text: "Feed"))
      |> visit("/messages/#{conv.id}")
      |> assert_has(css("#chat-window"))
      |> assert_has(css("p", text: "Hello there!"))
    end

    test "chat window shows input and send button", %{session: session} do
      user1 = create_test_user(%{"display_name" => "Sender"})
      user2 = create_test_user(%{"display_name" => "Receiver"})

      {:ok, conv} = Messaging.create_dm(user1.id, user2.id)

      session
      |> login(user1)
      |> assert_has(css("h1", text: "Feed"))
      |> visit("/messages/#{conv.id}")
      |> assert_has(css("#chat-window"))
      |> assert_has(css("input[name='body']"))
      |> assert_has(css("button[type='submit']"))
    end

    test "group chat shows group name on messages page", %{session: session} do
      user1 = create_test_user(%{"display_name" => "GroupMember1"})
      user2 = create_test_user(%{"display_name" => "GroupMember2"})
      user3 = create_test_user(%{"display_name" => "GroupMember3"})

      {:ok, _conv} = Messaging.create_group(user1.id, "Test Group", [user2.id, user3.id])

      session
      |> login(user1)
      |> assert_has(css("h1", text: "Feed"))
      |> visit("/messages")
      |> assert_has(css("h1", text: "Messages"))
      |> assert_has(css("p", text: "Test Group"))
    end
  end
end
