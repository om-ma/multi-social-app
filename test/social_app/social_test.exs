defmodule SocialApp.SocialTest do
  use SocialApp.DataCase, async: true

  alias SocialApp.Social
  alias SocialApp.Accounts

  defp create_user(attrs \\ %{}) do
    num = System.unique_integer([:positive])

    defaults = %{
      "username" => "user_#{num}",
      "email" => "user_#{num}@test.com",
      "display_name" => "User #{num}",
      "password" => "password123"
    }

    {:ok, user} = Accounts.register_user(Map.merge(defaults, attrs))
    user
  end

  describe "follow/2" do
    test "creates a follow relationship" do
      user_a = create_user()
      user_b = create_user()

      assert {:ok, _follow} = Social.follow(user_a.id, user_b.id)
      assert Social.following?(user_a.id, user_b.id)
    end

    test "increments counters" do
      user_a = create_user()
      user_b = create_user()

      {:ok, _} = Social.follow(user_a.id, user_b.id)

      user_a = Accounts.get_user!(user_a.id)
      user_b = Accounts.get_user!(user_b.id)

      assert user_a.following_count == 1
      assert user_b.followers_count == 1
    end

    test "creates a notification" do
      user_a = create_user()
      user_b = create_user()

      {:ok, _} = Social.follow(user_a.id, user_b.id)

      notifications = Social.list_notifications(user_b.id)
      assert length(notifications) == 1
      assert hd(notifications).type == "follow"
      assert hd(notifications).actor_id == user_a.id
    end

    test "cannot follow self" do
      user = create_user()
      assert {:error, :cannot_follow_self} = Social.follow(user.id, user.id)
    end

    test "cannot follow same user twice" do
      user_a = create_user()
      user_b = create_user()

      {:ok, _} = Social.follow(user_a.id, user_b.id)
      assert {:error, _} = Social.follow(user_a.id, user_b.id)
    end
  end

  describe "unfollow/2" do
    test "removes a follow relationship" do
      user_a = create_user()
      user_b = create_user()

      {:ok, _} = Social.follow(user_a.id, user_b.id)
      assert :ok = Social.unfollow(user_a.id, user_b.id)
      refute Social.following?(user_a.id, user_b.id)
    end

    test "decrements counters" do
      user_a = create_user()
      user_b = create_user()

      {:ok, _} = Social.follow(user_a.id, user_b.id)
      :ok = Social.unfollow(user_a.id, user_b.id)

      user_a = Accounts.get_user!(user_a.id)
      user_b = Accounts.get_user!(user_b.id)

      assert user_a.following_count == 0
      assert user_b.followers_count == 0
    end

    test "returns error when not following" do
      user_a = create_user()
      user_b = create_user()

      assert {:error, :not_following} = Social.unfollow(user_a.id, user_b.id)
    end
  end

  describe "following?/2" do
    test "returns true when following" do
      user_a = create_user()
      user_b = create_user()

      {:ok, _} = Social.follow(user_a.id, user_b.id)
      assert Social.following?(user_a.id, user_b.id)
    end

    test "returns false when not following" do
      user_a = create_user()
      user_b = create_user()

      refute Social.following?(user_a.id, user_b.id)
    end
  end

  describe "list_followers/2" do
    test "returns followers of a user" do
      user_a = create_user()
      user_b = create_user()
      user_c = create_user()

      {:ok, _} = Social.follow(user_b.id, user_a.id)
      {:ok, _} = Social.follow(user_c.id, user_a.id)

      followers = Social.list_followers(user_a.id)
      follower_ids = Enum.map(followers, & &1.id)

      assert length(followers) == 2
      assert user_b.id in follower_ids
      assert user_c.id in follower_ids
    end

    test "supports pagination" do
      user_a = create_user()

      for _ <- 1..5 do
        other = create_user()
        Social.follow(other.id, user_a.id)
      end

      assert length(Social.list_followers(user_a.id, limit: 2)) == 2
      assert length(Social.list_followers(user_a.id, limit: 2, offset: 4)) == 1
    end
  end

  describe "list_following/2" do
    test "returns users that a user follows" do
      user_a = create_user()
      user_b = create_user()
      user_c = create_user()

      {:ok, _} = Social.follow(user_a.id, user_b.id)
      {:ok, _} = Social.follow(user_a.id, user_c.id)

      following = Social.list_following(user_a.id)
      following_ids = Enum.map(following, & &1.id)

      assert length(following) == 2
      assert user_b.id in following_ids
      assert user_c.id in following_ids
    end
  end

  describe "list_notifications/2" do
    test "returns notifications for a user" do
      user_a = create_user()
      user_b = create_user()

      {:ok, _} = Social.follow(user_a.id, user_b.id)

      notifications = Social.list_notifications(user_b.id)
      assert length(notifications) == 1
      assert hd(notifications).actor.id == user_a.id
    end
  end

  describe "mark_notifications_read/1" do
    test "marks all notifications as read" do
      user_a = create_user()
      user_b = create_user()

      {:ok, _} = Social.follow(user_a.id, user_b.id)

      assert Social.unread_notification_count(user_b.id) == 1

      Social.mark_notifications_read(user_b.id)

      assert Social.unread_notification_count(user_b.id) == 0
    end
  end

  describe "unread_notification_count/1" do
    test "returns count of unread notifications" do
      user_a = create_user()
      user_b = create_user()
      user_c = create_user()

      {:ok, _} = Social.follow(user_a.id, user_b.id)
      {:ok, _} = Social.follow(user_c.id, user_b.id)

      assert Social.unread_notification_count(user_b.id) == 2
    end
  end

  describe "list_suggested_users/2" do
    test "returns users not followed (excluding self)" do
      user_a = create_user()
      user_b = create_user()
      user_c = create_user()

      {:ok, _} = Social.follow(user_a.id, user_b.id)

      suggested = Social.list_suggested_users(user_a.id)
      suggested_ids = Enum.map(suggested, & &1.id)

      assert user_c.id in suggested_ids
      refute user_b.id in suggested_ids
      refute user_a.id in suggested_ids
    end
  end

  describe "search_users/1" do
    test "finds users by username" do
      user = create_user(%{"username" => "searchable_user"})

      results = Social.search_users("searchable")
      assert length(results) >= 1
      assert user.id in Enum.map(results, & &1.id)
    end

    test "finds users by display_name" do
      user = create_user(%{"display_name" => "Findable Person"})

      results = Social.search_users("Findable")
      assert length(results) >= 1
      assert user.id in Enum.map(results, & &1.id)
    end

    test "returns empty list for empty query" do
      assert Social.search_users("") == []
      assert Social.search_users(nil) == []
    end
  end
end
