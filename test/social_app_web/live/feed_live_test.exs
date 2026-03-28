defmodule SocialAppWeb.FeedLiveTest do
  use SocialAppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias SocialApp.Repo
  alias SocialApp.Feed

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
    conn
    |> Plug.Test.init_test_session(%{user_id: user.id})
  end

  describe "mount" do
    test "redirects when not authenticated", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/login"}}} = live(conn, ~p"/feed")
    end

    test "renders feed page when authenticated", %{conn: conn} do
      user = create_user()
      conn = log_in(conn, user)

      {:ok, view, html} = live(conn, ~p"/feed")
      assert html =~ "Feed"
      assert has_element?(view, "h1", "Feed")
    end

    test "displays posts in feed", %{conn: conn} do
      user = create_user()
      {:ok, _post} = Feed.create_post(user.id, %{"content" => "Hello from the feed!"})

      conn = log_in(conn, user)
      {:ok, _view, html} = live(conn, ~p"/feed")
      assert html =~ "Hello from the feed!"
    end
  end

  describe "like/unlike" do
    test "toggles like on a post", %{conn: conn} do
      user = create_user()
      {:ok, post} = Feed.create_post(user.id, %{"content" => "Like me!"})

      conn = log_in(conn, user)
      {:ok, view, _html} = live(conn, ~p"/feed")

      # Like
      view
      |> element("button[phx-click=\"toggle_like\"][phx-value-post-id=\"#{post.id}\"]")
      |> render_click()

      assert render(view) =~ "1"

      # Unlike
      view
      |> element("button[phx-click=\"toggle_like\"][phx-value-post-id=\"#{post.id}\"]")
      |> render_click()

      assert render(view) =~ "0"
    end
  end

  describe "create post" do
    test "creates a new post via modal", %{conn: conn} do
      user = create_user()
      conn = log_in(conn, user)

      {:ok, view, _html} = live(conn, ~p"/feed")

      # Open modal
      view |> element("button[phx-click=open_create_post]") |> render_click()
      assert render(view) =~ "Create Post"

      # Submit
      view
      |> element("form[phx-submit=create_post]")
      |> render_submit(%{content: "My new post!", media_type: ""})

      html = render(view)
      assert html =~ "My new post!"
    end
  end

  describe "load more" do
    test "loads more posts on click", %{conn: conn} do
      user = create_user()

      for i <- 1..12 do
        Feed.create_post(user.id, %{"content" => "Post number #{i}"})
      end

      conn = log_in(conn, user)
      {:ok, view, html} = live(conn, ~p"/feed")

      # Should show load more button (10 posts per page, 12 total)
      assert html =~ "Load more"

      # Click load more
      view |> element("button[phx-click=load_more]") |> render_click()
      html = render(view)

      # Should now contain all posts and no load more
      assert html =~ "Post number 1"
      refute html =~ "Load more"
    end
  end
end
