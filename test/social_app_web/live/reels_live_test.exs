defmodule SocialAppWeb.ReelsLiveTest do
  use SocialAppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias SocialApp.Accounts
  alias SocialApp.Reels

  @user_attrs %{
    "username" => "reelviewer",
    "email" => "reelviewer@example.com",
    "display_name" => "Reel Viewer",
    "password" => "password123"
  }

  defp create_user(attrs \\ @user_attrs) do
    {:ok, user} = Accounts.register_user(attrs)
    user
  end

  defp log_in(conn, user) do
    conn
    |> Plug.Test.init_test_session(%{user_id: user.id})
  end

  defp create_reel(user, attrs \\ %{}) do
    default = %{"video_url" => "https://example.com/video.mp4", "caption" => "Test reel caption"}
    {:ok, reel} = Reels.create_reel(user, Map.merge(default, attrs))
    reel
  end

  describe "ReelsLive" do
    test "renders reels page with For You tab active", %{conn: conn} do
      user = create_user()
      conn = log_in(conn, user)
      create_reel(user)

      {:ok, _view, html} = live(conn, ~p"/reels")

      assert html =~ "For You"
      assert html =~ "Following"
      assert html =~ "Test reel caption"
    end

    test "shows empty state when no reels", %{conn: conn} do
      user = create_user()
      conn = log_in(conn, user)

      {:ok, _view, html} = live(conn, ~p"/reels")
      assert html =~ "No reels yet"
    end

    test "switches to Following tab", %{conn: conn} do
      user = create_user()
      conn = log_in(conn, user)

      {:ok, view, _html} = live(conn, ~p"/reels")

      html = view |> element("button", "Following") |> render_click()
      assert html =~ "Follow some users to see their reels"
    end

    test "switches back to For You tab", %{conn: conn} do
      user = create_user()
      conn = log_in(conn, user)
      create_reel(user, %{"caption" => "A for you reel"})

      {:ok, view, _html} = live(conn, ~p"/reels")

      view |> element("button", "Following") |> render_click()
      html = view |> element("button", "For You") |> render_click()
      assert html =~ "A for you reel"
    end

    test "can like and unlike a reel", %{conn: conn} do
      user = create_user()
      conn = log_in(conn, user)
      reel = create_reel(user)

      {:ok, view, _html} = live(conn, ~p"/reels")

      # Like
      html =
        view
        |> element(~s|button[phx-click="toggle_like"][phx-value-reel-id="#{reel.id}"]|)
        |> render_click()

      # The likes count should have incremented
      assert html =~ "1"

      # Unlike
      html =
        view
        |> element(~s|button[phx-click="toggle_like"][phx-value-reel-id="#{reel.id}"]|)
        |> render_click()

      assert html =~ "0"
    end

    test "opens and closes upload modal", %{conn: conn} do
      user = create_user()
      conn = log_in(conn, user)

      {:ok, view, _html} = live(conn, ~p"/reels")

      html = view |> element("button[phx-click=open_upload_modal]") |> render_click()
      assert html =~ "Create Reel"
      assert html =~ "Tap to upload video"

      html = view |> element("button[phx-click=close_upload_modal]") |> render_click()
      refute html =~ "Create Reel"
    end

    test "creates a reel via modal", %{conn: conn} do
      user = create_user()
      conn = log_in(conn, user)

      {:ok, view, _html} = live(conn, ~p"/reels")

      view |> element("button[phx-click=open_upload_modal]") |> render_click()

      html =
        view
        |> element("form[phx-submit=save_reel]")
        |> render_submit(%{"caption" => "My new reel"})

      assert html =~ "My new reel"
      refute html =~ "Create Reel"
    end

    test "displays user info on reel", %{conn: conn} do
      user = create_user()
      conn = log_in(conn, user)
      create_reel(user)

      {:ok, _view, html} = live(conn, ~p"/reels")
      assert html =~ user.username
    end
  end
end
