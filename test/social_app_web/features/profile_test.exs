defmodule SocialAppWeb.Features.ProfileTest do
  use SocialAppWeb.FeatureCase, async: false

  alias SocialApp.Feed

  describe "profile page" do
    test "own profile shows Edit Profile link and display name", %{session: session} do
      user = create_test_user(%{"display_name" => "OwnProfile"})

      session
      |> login(user)
      |> assert_has(css("h1", text: "Feed"))
      |> visit("/u/#{user.username}")
      |> assert_has(css("h1", text: "OwnProfile"))
      |> assert_has(css("a", text: "Edit Profile"))
      |> refute_has(css("button[phx-click='follow']"))
    end

    test "other user's profile shows Follow button and name", %{session: session} do
      user = create_test_user()
      other = create_test_user(%{"display_name" => "OtherUserXY"})

      session
      |> login(user)
      |> assert_has(css("h1", text: "Feed"))
      |> visit("/u/#{other.username}")
      |> assert_has(css("h1", text: "OtherUserXY"))
      |> assert_has(css("button[phx-click='follow']", text: "Follow"))
    end

    test "follow and unfollow a user toggles button", %{session: session} do
      user = create_test_user()
      other = create_test_user(%{"display_name" => "ToggleFollow"})

      session =
        session
        |> login(user)
        |> assert_has(css("h1", text: "Feed"))
        |> visit("/u/#{other.username}")
        |> assert_has(css("h1", text: "ToggleFollow"))
        |> click(css("button[phx-click='follow']"))
        |> assert_has(css("button[phx-click='unfollow']", text: "Following"))

      session
      |> click(css("button[phx-click='unfollow']"))
      |> assert_has(css("button[phx-click='follow']", text: "Follow"))
    end

    test "profile shows display name in header", %{session: session} do
      user = create_test_user(%{"display_name" => "ShowName"})

      session
      |> login(user)
      |> assert_has(css("h1", text: "Feed"))
      |> visit("/u/#{user.username}")
      |> assert_has(css("h1", text: "ShowName"))
    end

    test "profile shows followers and following stat buttons", %{session: session} do
      user = create_test_user(%{"display_name" => "StatUser"})

      session
      |> login(user)
      |> assert_has(css("h1", text: "Feed"))
      |> visit("/u/#{user.username}")
      |> assert_has(css("h1", text: "StatUser"))
      |> assert_has(css("button[phx-click='show_following']"))
      |> assert_has(css("button[phx-click='show_followers']"))
    end

    test "profile shows empty posts message when no posts", %{session: session} do
      user = create_test_user(%{"display_name" => "EmptyPosts"})

      session
      |> login(user)
      |> assert_has(css("h1", text: "Feed"))
      |> visit("/u/#{user.username}")
      |> assert_has(css("h1", text: "EmptyPosts"))
      |> assert_has(css("p", text: "No posts yet"))
    end

    test "profile shows posts grid when posts exist", %{session: session} do
      user = create_test_user(%{"display_name" => "GridUser"})
      Feed.create_post(user.id, %{"content" => "Grid post content"})

      session
      |> login(user)
      |> assert_has(css("h1", text: "Feed"))
      |> visit("/u/#{user.username}")
      |> assert_has(css("h1", text: "GridUser"))
      |> assert_has(css("div.aspect-square"))
    end
  end
end
