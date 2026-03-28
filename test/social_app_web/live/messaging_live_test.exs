defmodule SocialAppWeb.MessagingLiveTest do
  use SocialAppWeb.ConnCase

  import Phoenix.LiveViewTest

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

  defp log_in(conn, user) do
    conn |> Plug.Test.init_test_session(%{user_id: user.id})
  end

  describe "MessagingLive" do
    test "renders messages page", %{conn: conn} do
      user = create_user(%{username: "mlive1", email: "mlive1@test.com"})
      conn = log_in(conn, user)

      {:ok, _view, html} = live(conn, "/messages")
      assert html =~ "Messages"
    end

    test "shows conversations list", %{conn: conn} do
      user1 = create_user(%{username: "mlive2", email: "mlive2@test.com"})

      user2 =
        create_user(%{username: "mlive3", email: "mlive3@test.com", display_name: "Bob Test"})

      {:ok, conv} = Messaging.create_dm(user1.id, user2.id)
      Messaging.send_message(conv.id, user2.id, %{"body" => "Hey there!"})

      conn = log_in(conn, user1)
      {:ok, _view, html} = live(conn, "/messages")

      assert html =~ "Bob Test"
      assert html =~ "Hey there!"
    end

    test "shows empty state when no conversations", %{conn: conn} do
      user = create_user(%{username: "mlive4", email: "mlive4@test.com"})
      conn = log_in(conn, user)

      {:ok, _view, html} = live(conn, "/messages")
      assert html =~ "No conversations yet"
    end
  end

  describe "ChatWindowLive" do
    test "renders chat window", %{conn: conn} do
      user1 = create_user(%{username: "cw1", email: "cw1@test.com"})
      user2 = create_user(%{username: "cw2", email: "cw2@test.com", display_name: "ChatPartner"})

      {:ok, conv} = Messaging.create_dm(user1.id, user2.id)

      conn = log_in(conn, user1)
      {:ok, _view, html} = live(conn, "/messages/#{conv.id}")

      assert html =~ "ChatPartner"
    end

    test "displays messages", %{conn: conn} do
      user1 = create_user(%{username: "cw3", email: "cw3@test.com"})
      user2 = create_user(%{username: "cw4", email: "cw4@test.com"})

      {:ok, conv} = Messaging.create_dm(user1.id, user2.id)
      Messaging.send_message(conv.id, user1.id, %{"body" => "Hello World"})

      conn = log_in(conn, user1)
      {:ok, _view, html} = live(conn, "/messages/#{conv.id}")

      assert html =~ "Hello World"
    end

    test "can send a message", %{conn: conn} do
      user1 = create_user(%{username: "cw5", email: "cw5@test.com"})
      user2 = create_user(%{username: "cw6", email: "cw6@test.com"})

      {:ok, conv} = Messaging.create_dm(user1.id, user2.id)

      conn = log_in(conn, user1)
      {:ok, view, _html} = live(conn, "/messages/#{conv.id}")

      view
      |> form("form", %{body: "Test message"})
      |> render_submit()

      html = render(view)
      assert html =~ "Test message"
    end

    test "shows group chat members", %{conn: conn} do
      user1 = create_user(%{username: "cw7", email: "cw7@test.com", display_name: "Alice"})
      user2 = create_user(%{username: "cw8", email: "cw8@test.com", display_name: "Bob"})
      user3 = create_user(%{username: "cw9", email: "cw9@test.com", display_name: "Charlie"})

      {:ok, conv} = Messaging.create_group(user1.id, "Test Group", [user2.id, user3.id])

      conn = log_in(conn, user1)
      {:ok, _view, html} = live(conn, "/messages/#{conv.id}")

      assert html =~ "Test Group"
    end

    test "does not send empty messages", %{conn: conn} do
      user1 = create_user(%{username: "cw10", email: "cw10@test.com"})
      user2 = create_user(%{username: "cw11", email: "cw11@test.com"})

      {:ok, conv} = Messaging.create_dm(user1.id, user2.id)

      conn = log_in(conn, user1)
      {:ok, view, _html} = live(conn, "/messages/#{conv.id}")

      view
      |> form("form", %{body: "   "})
      |> render_submit()

      messages = Messaging.list_messages(conv.id)
      assert messages == []
    end
  end
end
