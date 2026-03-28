defmodule SocialAppWeb.ProfileLiveTest do
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
      assert {:error, {:redirect, %{to: "/login"}}} = live(conn, ~p"/u/someuser")
    end

    test "renders own profile", %{conn: conn} do
      user = create_user(%{username: "alice", display_name: "Alice"})
      conn = log_in(conn, user)

      {:ok, _view, html} = live(conn, ~p"/u/alice")
      assert html =~ "Alice"
      assert html =~ "@alice"
      assert html =~ "Edit Profile"
    end

    test "renders another user's profile with follow button", %{conn: conn} do
      user = create_user()
      _other = create_user(%{username: "bob", display_name: "Bob"})
      conn = log_in(conn, user)

      {:ok, _view, html} = live(conn, ~p"/u/bob")
      assert html =~ "Bob"
      assert html =~ "Follow"
    end

    test "redirects when user not found", %{conn: conn} do
      user = create_user()
      conn = log_in(conn, user)

      assert {:error, {:redirect, %{to: "/feed"}}} = live(conn, ~p"/u/nonexistent")
    end
  end

  describe "follow/unfollow" do
    test "follow button works", %{conn: conn} do
      user = create_user()
      other = create_user(%{username: "target"})
      conn = log_in(conn, user)

      {:ok, view, _html} = live(conn, ~p"/u/target")

      # Click follow
      html = view |> element("button[phx-click=follow]") |> render_click()
      assert html =~ "Following"
      assert Social.following?(user.id, other.id)
    end

    test "unfollow button works", %{conn: conn} do
      user = create_user()
      other = create_user(%{username: "target2"})
      Social.follow(user.id, other.id)
      conn = log_in(conn, user)

      {:ok, view, _html} = live(conn, ~p"/u/target2")

      # Click unfollow (the button says "Following")
      html = view |> element("button[phx-click=unfollow]") |> render_click()
      assert html =~ "Follow"
      refute Social.following?(user.id, other.id)
    end
  end

  describe "followers/following modal" do
    test "shows followers modal", %{conn: conn} do
      user = create_user(%{username: "main_user"})
      follower = create_user(%{username: "follower1", display_name: "Follower One"})
      Social.follow(follower.id, user.id)
      conn = log_in(conn, user)

      {:ok, view, _html} = live(conn, ~p"/u/main_user")

      html = view |> element("button", "Followers") |> render_click()
      assert html =~ "Follower One"
    end

    test "shows following modal", %{conn: conn} do
      user = create_user(%{username: "main_user2"})
      followed = create_user(%{username: "followed1", display_name: "Followed One"})
      Social.follow(user.id, followed.id)
      conn = log_in(conn, user)

      {:ok, view, _html} = live(conn, ~p"/u/main_user2")

      html = view |> element("button[phx-click=show_following]") |> render_click()
      assert html =~ "Followed One"
    end
  end
end
