defmodule SocialAppWeb.Features.NavigationTest do
  use SocialAppWeb.FeatureCase, async: false

  describe "navigation" do
    test "feed page renders with sidebar and bottom nav", %{session: session} do
      user = create_test_user()

      session
      |> resize_window(1280, 800)
      |> login(user)
      |> assert_has(css("h1", text: "Feed"))
      |> assert_has(css("aside", count: 2))
    end

    test "navigate to explore via sidebar", %{session: session} do
      user = create_test_user()

      session
      |> resize_window(1280, 800)
      |> login(user)
      |> assert_has(css("h1", text: "Feed"))
      |> click(css("a[href='/explore']"))
      |> assert_has(css("h1", text: "Explore"))
    end

    test "navigate to messages via sidebar", %{session: session} do
      user = create_test_user()

      session
      |> resize_window(1280, 800)
      |> login(user)
      |> assert_has(css("h1", text: "Feed"))
      |> click(css("a[href='/messages']"))
      |> assert_has(css("h1", text: "Messages"))
    end

    test "navigate to notifications via sidebar", %{session: session} do
      user = create_test_user()

      session
      |> resize_window(1280, 800)
      |> login(user)
      |> assert_has(css("h1", text: "Feed"))
      |> click(css("a[href='/notifications']"))
      |> assert_has(css("h1", text: "Notifications"))
    end

    test "navigate to own profile via sidebar", %{session: session} do
      user = create_test_user(%{"display_name" => "NavUser"})

      session
      |> resize_window(1280, 800)
      |> login(user)
      |> assert_has(css("h1", text: "Feed"))
      |> click(css("nav a[href='/u/#{user.username}']"))
      |> assert_has(css("h1", text: "NavUser"))
    end

    test "create post button opens modal", %{session: session} do
      user = create_test_user()

      session
      |> resize_window(1280, 800)
      |> login(user)
      |> assert_has(css("h1", text: "Feed"))
      |> click(css("button[phx-click='open_create_post']", count: :any, at: 0))
      |> assert_has(css("h2", text: "Create Post"))
      |> assert_has(css("textarea[name='content']"))
    end
  end
end
