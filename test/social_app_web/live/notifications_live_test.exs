defmodule SocialAppWeb.NotificationsLiveTest do
  use SocialAppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias SocialApp.Repo
  alias SocialApp.Social

  defp create_user(attrs \\ %{}) do
    num = System.unique_integer([:positive])

    defaults = %{
      username: "user_#{num}",
      email: "user_#{num}@test.com",
      display_name: "User #{num}",
      password: "password123"
    }

    {:ok, user} =
      %SocialApp.Accounts.User{}
      |> SocialApp.Accounts.User.registration_changeset(Map.merge(defaults, attrs))
      |> Repo.insert()

    user
  end

  defp log_in(conn, user) do
    conn |> Plug.Test.init_test_session(%{user_id: user.id})
  end

  describe "mount" do
    test "redirects when not authenticated", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/login"}}} = live(conn, ~p"/notifications")
    end

    test "renders notifications page", %{conn: conn} do
      user = create_user()
      conn = log_in(conn, user)

      {:ok, _view, html} = live(conn, ~p"/notifications")
      assert html =~ "Notifications"
    end

    test "shows empty state when no notifications", %{conn: conn} do
      user = create_user()
      conn = log_in(conn, user)

      {:ok, _view, html} = live(conn, ~p"/notifications")
      assert html =~ "No notifications yet"
    end

    test "shows notifications", %{conn: conn} do
      user = create_user()
      actor = create_user(%{display_name: "Notify Actor"})
      Social.follow(actor.id, user.id)

      conn = log_in(conn, user)

      {:ok, _view, html} = live(conn, ~p"/notifications")
      assert html =~ "Notify Actor"
      assert html =~ "started following you"
    end

    test "marks notifications as read on mount", %{conn: conn} do
      user = create_user()
      actor = create_user()
      Social.follow(actor.id, user.id)

      assert Social.unread_notification_count(user.id) == 1

      conn = log_in(conn, user)
      {:ok, _view, _html} = live(conn, ~p"/notifications")

      assert Social.unread_notification_count(user.id) == 0
    end
  end
end
