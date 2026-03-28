defmodule SocialAppWeb.NavigationTest do
  use SocialAppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias SocialApp.Repo

  defp create_user(attrs \\ %{}) do
    num = System.unique_integer([:positive])

    defaults = %{
      username: "navuser_#{num}",
      email: "navuser_#{num}@test.com",
      display_name: "Nav User #{num}",
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

  describe "layout structure" do
    test "renders sidebar with logo and nav items", %{conn: conn} do
      user = create_user()
      conn = log_in(conn, user)

      {:ok, _view, html} = live(conn, ~p"/feed")

      # Logo
      assert html =~ "Social"
      assert html =~ "App"

      # Nav items
      assert html =~ "Home"
      assert html =~ "Explore"
      assert html =~ "Reels"
      assert html =~ "Messages"
      assert html =~ "Notifications"
      assert html =~ "Profile"

      # Create Post button
      assert html =~ "Create Post"

      # User footer
      assert html =~ user.username
    end

    test "renders search input in sidebar", %{conn: conn} do
      user = create_user()
      conn = log_in(conn, user)

      {:ok, _view, html} = live(conn, ~p"/feed")

      assert html =~ "Search..."
    end

    test "renders bottom nav for mobile", %{conn: conn} do
      user = create_user()
      conn = log_in(conn, user)

      {:ok, _view, html} = live(conn, ~p"/feed")

      # Bottom nav items (text labels)
      assert html =~ "Home"
      assert html =~ "Reels"
      assert html =~ "Messages"
      assert html =~ "Profile"
    end

    test "highlights active nav item on feed page", %{conn: conn} do
      user = create_user()
      conn = log_in(conn, user)

      {:ok, _view, html} = live(conn, ~p"/feed")

      # Active state uses sa-green color class
      assert html =~ "bg-sa-green/20"
    end

    test "sidebar renders on all pages", %{conn: conn} do
      user = create_user()
      conn = log_in(conn, user)

      # Test multiple pages render the sidebar
      for path <- [~p"/feed", ~p"/explore", ~p"/notifications"] do
        {:ok, _view, html} = live(conn, path)
        assert html =~ "Create Post", "Sidebar missing on #{path}"
        assert html =~ "Social", "Logo missing on #{path}"
      end
    end
  end

  describe "navigation between pages" do
    test "navigating from feed to explore", %{conn: conn} do
      user = create_user()
      conn = log_in(conn, user)

      {:ok, view, _html} = live(conn, ~p"/feed")

      # Click explore link in sidebar
      {:ok, _explore_view, html} =
        view
        |> element("a[href='/explore']")
        |> render_click()
        |> follow_redirect(conn)

      assert html =~ "Explore"
    end

    test "navigating from feed to notifications", %{conn: conn} do
      user = create_user()
      conn = log_in(conn, user)

      {:ok, view, _html} = live(conn, ~p"/feed")

      {:ok, _notif_view, html} =
        view
        |> element("a[href='/notifications']")
        |> render_click()
        |> follow_redirect(conn)

      assert html =~ "Notifications"
    end
  end

  describe "create post modal" do
    test "opens create post modal from sidebar button", %{conn: conn} do
      user = create_user()
      conn = log_in(conn, user)

      {:ok, view, _html} = live(conn, ~p"/explore")

      # Open modal via sidebar Create Post button
      view
      |> element("button.w-full.bg-sa-gold[phx-click=open_create_post]")
      |> render_click()

      html = render(view)
      assert html =~ "Create Post"
      assert html =~ "on your mind"
    end

    test "create post modal works from non-feed pages", %{conn: conn} do
      user = create_user()
      conn = log_in(conn, user)

      {:ok, view, _html} = live(conn, ~p"/notifications")

      # Open modal
      view
      |> element("button.w-full.bg-sa-gold[phx-click=open_create_post]")
      |> render_click()

      # Submit post
      view
      |> element("form[phx-submit=create_post]")
      |> render_submit(%{content: "Post from notifications page!", media_type: ""})

      # Should redirect to feed
      {path, _flash} = assert_redirect(view)
      assert path == "/feed"
    end
  end

  describe "sidebar search" do
    test "search returns matching users", %{conn: conn} do
      user = create_user(%{username: "searcher"})
      _target = create_user(%{username: "searchable_target", display_name: "Searchable"})
      conn = log_in(conn, user)

      {:ok, view, _html} = live(conn, ~p"/feed")

      # Type in search
      html =
        view
        |> element("input[name=search]")
        |> render_keyup(%{"value" => "searchable"})

      assert html =~ "searchable_target"
    end

    test "search shows no results message for unmatched query", %{conn: conn} do
      user = create_user()
      conn = log_in(conn, user)

      {:ok, view, _html} = live(conn, ~p"/feed")

      html =
        view
        |> element("input[name=search]")
        |> render_keyup(%{"value" => "zzzznonexistent"})

      assert html =~ "No results found"
    end

    test "clearing search hides dropdown", %{conn: conn} do
      user = create_user()
      conn = log_in(conn, user)

      {:ok, view, _html} = live(conn, ~p"/feed")

      html =
        view
        |> element("input[name=search]")
        |> render_keyup(%{"value" => ""})

      refute html =~ "No results found"
    end
  end

  describe "RTL support" do
    test "sidebar uses RTL-compatible directional classes", %{conn: conn} do
      user = create_user()
      conn = log_in(conn, user)

      {:ok, _view, html} = live(conn, ~p"/feed")

      # Sidebar uses border-e (logical end border) for RTL support
      assert html =~ "border-e"
      # Bottom nav uses rtl:flex-row-reverse
      assert html =~ "rtl:flex-row-reverse"
    end
  end
end
