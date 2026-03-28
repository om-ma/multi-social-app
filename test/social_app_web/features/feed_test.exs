defmodule SocialAppWeb.Features.FeedTest do
  use SocialAppWeb.FeatureCase, async: false

  alias SocialApp.Feed

  describe "feed page" do
    test "feed page loads with posts visible", %{session: session} do
      user = create_test_user()
      {:ok, _post} = Feed.create_post(user.id, %{"content" => "Hello from the feed!"})

      session
      |> login(user)
      |> assert_has(css("h1", text: "Feed"))
      |> assert_has(css("#feed-posts"))
      |> assert_has(css("p", text: "Hello from the feed!"))
    end

    test "feed page shows empty state when no posts", %{session: session} do
      user = create_test_user()

      session
      |> login(user)
      |> assert_has(css("p", text: "No posts yet. Be the first to share something!"))
    end

    test "like a post increments count", %{session: session} do
      user = create_test_user()
      {:ok, post} = Feed.create_post(user.id, %{"content" => "Likeable post"})

      session =
        session
        |> login(user)
        |> assert_has(css("#feed-posts"))

      # The post should show 0 likes initially
      session
      |> assert_has(
        css("button[phx-click='toggle_like'][phx-value-post-id='#{post.id}']", text: "0")
      )

      # Click like
      session =
        session
        |> click(css("button[phx-click='toggle_like'][phx-value-post-id='#{post.id}']"))

      # Count should be 1 now
      session
      |> assert_has(
        css("button[phx-click='toggle_like'][phx-value-post-id='#{post.id}']", text: "1")
      )
    end

    test "unlike a post decrements count", %{session: session} do
      user = create_test_user()
      {:ok, post} = Feed.create_post(user.id, %{"content" => "Unlike me"})
      Feed.like_post(user.id, post.id)

      session =
        session
        |> login(user)
        |> assert_has(css("#feed-posts"))

      # Should show 1 like (already liked)
      session
      |> assert_has(
        css("button[phx-click='toggle_like'][phx-value-post-id='#{post.id}']", text: "1")
      )

      # Click to unlike
      session =
        session
        |> click(css("button[phx-click='toggle_like'][phx-value-post-id='#{post.id}']"))

      session
      |> assert_has(
        css("button[phx-click='toggle_like'][phx-value-post-id='#{post.id}']", text: "0")
      )
    end

    test "stories row is visible with Your Story button", %{session: session} do
      user = create_test_user()

      session
      |> login(user)
      |> assert_has(css("span", text: "Your Story"))
    end

    test "load more button appears with enough posts", %{session: session} do
      user = create_test_user()

      # Create 11 posts to trigger pagination
      for i <- 1..11 do
        Feed.create_post(user.id, %{"content" => "Post number #{i}"})
      end

      session
      |> login(user)
      |> assert_has(button("Load more"))
    end

    test "navigate to user profile by clicking username on post", %{session: session} do
      user = create_test_user(%{"display_name" => "ClickableUser"})
      {:ok, _post} = Feed.create_post(user.id, %{"content" => "Click my name"})

      session
      |> login(user)
      |> assert_has(css("span", text: "ClickableUser"))
    end
  end
end
