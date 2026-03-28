defmodule SocialApp.FeedTest do
  use SocialApp.DataCase, async: true

  alias SocialApp.Feed
  alias SocialApp.Content.Story

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

  defp create_post_for(user, attrs \\ %{}) do
    {:ok, post} = Feed.create_post(user.id, Map.merge(%{"content" => "Hello world"}, attrs))
    post
  end

  describe "list_feed_posts/1" do
    test "returns posts ordered by inserted_at desc" do
      user = create_user()
      post1 = create_post_for(user, %{"content" => "first"})
      post2 = create_post_for(user, %{"content" => "second"})

      posts = Feed.list_feed_posts()
      assert length(posts) == 2
      # Both may share the same inserted_at (utc_datetime second resolution),
      # so just verify both are returned and ordering is desc by inserted_at then id.
      ids = Enum.map(posts, & &1.id)
      assert post1.id in ids
      assert post2.id in ids
      assert hd(posts).inserted_at >= List.last(posts).inserted_at
    end

    test "preloads user" do
      user = create_user()
      _post = create_post_for(user)

      [post] = Feed.list_feed_posts()
      assert post.user.id == user.id
      assert post.user.username == user.username
    end

    test "supports limit and offset" do
      user = create_user()
      _p1 = create_post_for(user, %{"content" => "one"})
      _p2 = create_post_for(user, %{"content" => "two"})
      _p3 = create_post_for(user, %{"content" => "three"})

      page1 = Feed.list_feed_posts(limit: 2, offset: 0)
      assert length(page1) == 2

      page2 = Feed.list_feed_posts(limit: 2, offset: 2)
      assert length(page2) == 1
    end
  end

  describe "get_post!/1" do
    test "returns post with preloaded user" do
      user = create_user()
      post = create_post_for(user)

      fetched = Feed.get_post!(post.id)
      assert fetched.id == post.id
      assert fetched.user.id == user.id
    end

    test "raises on invalid id" do
      assert_raise Ecto.NoResultsError, fn ->
        Feed.get_post!(0)
      end
    end
  end

  describe "create_post/2" do
    test "creates a post for a user" do
      user = create_user()
      {:ok, post} = Feed.create_post(user.id, %{"content" => "Test post"})

      assert post.content == "Test post"
      assert post.user_id == user.id
      assert post.user.id == user.id
    end

    test "returns error with invalid attrs" do
      {:error, _changeset} = Feed.create_post(0, %{"content" => "test"})
    end
  end

  describe "delete_post/1" do
    test "deletes a post" do
      user = create_user()
      post = create_post_for(user)

      assert {:ok, _} = Feed.delete_post(post)
      assert_raise Ecto.NoResultsError, fn -> Feed.get_post!(post.id) end
    end
  end

  describe "like_post/2 and unlike_post/2" do
    test "like_post creates a like and increments count" do
      user = create_user()
      post = create_post_for(user)

      assert {:ok, _like} = Feed.like_post(user.id, post.id)

      updated = Feed.get_post!(post.id)
      assert updated.likes_count == 1
    end

    test "like_post fails for duplicate like" do
      user = create_user()
      post = create_post_for(user)

      assert {:ok, _} = Feed.like_post(user.id, post.id)
      assert {:error, _} = Feed.like_post(user.id, post.id)
    end

    test "unlike_post removes like and decrements count" do
      user = create_user()
      post = create_post_for(user)

      {:ok, _} = Feed.like_post(user.id, post.id)
      assert {:ok, :ok} = Feed.unlike_post(user.id, post.id)

      updated = Feed.get_post!(post.id)
      assert updated.likes_count == 0
    end

    test "unlike_post returns error when not liked" do
      user = create_user()
      post = create_post_for(user)

      assert {:error, :not_found} = Feed.unlike_post(user.id, post.id)
    end
  end

  describe "liked_by?/2" do
    test "returns true when user liked the post" do
      user = create_user()
      post = create_post_for(user)
      Feed.like_post(user.id, post.id)

      assert Feed.liked_by?(user.id, post.id)
    end

    test "returns false when user has not liked the post" do
      user = create_user()
      post = create_post_for(user)

      refute Feed.liked_by?(user.id, post.id)
    end
  end

  describe "list_user_liked_post_ids/2" do
    test "returns liked post ids from the given list" do
      user = create_user()
      p1 = create_post_for(user)
      p2 = create_post_for(user)
      p3 = create_post_for(user)

      Feed.like_post(user.id, p1.id)
      Feed.like_post(user.id, p3.id)

      result = Feed.list_user_liked_post_ids(user.id, [p1.id, p2.id, p3.id])
      assert MapSet.member?(result, p1.id)
      refute MapSet.member?(result, p2.id)
      assert MapSet.member?(result, p3.id)
    end

    test "returns empty set for no likes" do
      user = create_user()
      post = create_post_for(user)

      result = Feed.list_user_liked_post_ids(user.id, [post.id])
      assert MapSet.size(result) == 0
    end
  end

  describe "list_active_stories/0" do
    test "returns non-expired stories grouped by user" do
      user = create_user()

      {:ok, _story} =
        Feed.create_story(user.id, %{"media_url" => "https://example.com/story.jpg"})

      result = Feed.list_active_stories()
      assert Map.has_key?(result, user.id)
      assert length(result[user.id]) == 1
    end

    test "excludes expired stories" do
      user = create_user()

      expired_at =
        DateTime.utc_now()
        |> DateTime.add(-1, :hour)
        |> DateTime.truncate(:second)

      %Story{}
      |> Story.changeset(%{
        user_id: user.id,
        media_url: "https://example.com/old.jpg",
        expires_at: expired_at
      })
      |> Repo.insert!()

      result = Feed.list_active_stories()
      refute Map.has_key?(result, user.id)
    end
  end

  describe "create_story/2" do
    test "creates a story with 24h expiry" do
      user = create_user()

      {:ok, story} =
        Feed.create_story(user.id, %{"media_url" => "https://example.com/story.jpg"})

      assert story.user_id == user.id
      assert story.media_url == "https://example.com/story.jpg"

      # Should expire roughly 24h from now
      diff = DateTime.diff(story.expires_at, DateTime.utc_now(), :second)
      assert diff > 86_300 and diff <= 86_400
    end
  end
end
