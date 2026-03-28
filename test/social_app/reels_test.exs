defmodule SocialApp.ReelsTest do
  use SocialApp.DataCase, async: true

  alias SocialApp.Reels
  alias SocialApp.Content.Reel
  alias SocialApp.Accounts

  @user_attrs %{
    "username" => "reeluser",
    "email" => "reel@example.com",
    "display_name" => "Reel User",
    "password" => "password123"
  }

  defp create_user(attrs \\ @user_attrs) do
    {:ok, user} = Accounts.register_user(attrs)
    user
  end

  defp create_reel(user, attrs \\ %{}) do
    default = %{"video_url" => "https://example.com/video.mp4", "caption" => "Test reel"}
    {:ok, reel} = Reels.create_reel(user, Map.merge(default, attrs))
    reel
  end

  describe "create_reel/2" do
    test "creates a reel with valid attributes" do
      user = create_user()

      {:ok, reel} =
        Reels.create_reel(user, %{
          "video_url" => "https://example.com/v.mp4",
          "caption" => "Hello"
        })

      assert reel.user_id == user.id
      assert reel.video_url == "https://example.com/v.mp4"
      assert reel.caption == "Hello"
      assert reel.views_count == 0
      assert reel.likes_count == 0
    end

    test "fails without video_url" do
      user = create_user()
      assert {:error, changeset} = Reels.create_reel(user, %{})
      assert "can't be blank" in errors_on(changeset).video_url
    end
  end

  describe "get_reel!/1" do
    test "returns reel with preloaded user" do
      user = create_user()
      reel = create_reel(user)
      fetched = Reels.get_reel!(reel.id)
      assert fetched.id == reel.id
      assert fetched.user.id == user.id
    end

    test "raises for non-existent reel" do
      assert_raise Ecto.NoResultsError, fn ->
        Reels.get_reel!(0)
      end
    end
  end

  describe "list_reels/1" do
    test "returns reels ordered by score desc" do
      user = create_user()
      r1 = create_reel(user, %{"caption" => "low"})
      r2 = create_reel(user, %{"caption" => "high"})

      # Give r2 a higher score
      Repo.update!(Ecto.Changeset.change(r2, score: 100.0))
      Repo.update!(Ecto.Changeset.change(r1, score: 10.0))

      [first | _] = Reels.list_reels()
      assert first.id == r2.id
    end

    test "paginates results" do
      user = create_user()
      for i <- 1..5, do: create_reel(user, %{"caption" => "reel #{i}"})

      page1 = Reels.list_reels(page: 1, page_size: 2)
      page2 = Reels.list_reels(page: 2, page_size: 2)
      assert length(page1) == 2
      assert length(page2) == 2
    end

    test "preloads user" do
      user = create_user()
      create_reel(user)
      [reel] = Reels.list_reels()
      assert reel.user.id == user.id
    end
  end

  describe "list_following_reels/2" do
    test "returns only reels from followed users" do
      user1 = create_user()

      user2 =
        create_user(%{
          "username" => "followed",
          "email" => "followed@example.com",
          "display_name" => "Followed",
          "password" => "password123"
        })

      user3 =
        create_user(%{
          "username" => "notfollowed",
          "email" => "notfollowed@example.com",
          "display_name" => "Not Followed",
          "password" => "password123"
        })

      # user1 follows user2
      Repo.insert!(%SocialApp.Social.Follow{follower_id: user1.id, following_id: user2.id})

      _reel2 = create_reel(user2, %{"caption" => "from followed"})
      _reel3 = create_reel(user3, %{"caption" => "from not followed"})

      reels = Reels.list_following_reels(user1.id)
      assert length(reels) == 1
      assert hd(reels).user_id == user2.id
    end

    test "returns empty when following no one" do
      user = create_user()
      assert Reels.list_following_reels(user.id) == []
    end
  end

  describe "increment_views/1" do
    test "increments views_count by 1" do
      user = create_user()
      reel = create_reel(user)
      assert reel.views_count == 0

      {:ok, updated} = Reels.increment_views(reel)
      assert updated.views_count == 1

      {:ok, updated2} = Reels.increment_views(updated)
      assert updated2.views_count == 2
    end
  end

  describe "recalculate_score/1" do
    test "computes score using formula" do
      user = create_user()
      reel = create_reel(user)

      # Set some counts
      Repo.update!(
        Ecto.Changeset.change(reel, likes_count: 10, comments_count: 5, views_count: 100)
      )

      {:ok, updated} = Reels.recalculate_score(reel)
      # score = (10*3) + (5*2) + (100*1) - (hours_old*0.5)
      # hours_old is very small, so score should be close to 140
      assert updated.score > 139.0
      assert updated.score <= 140.0
    end
  end

  describe "like_reel/2 and unlike_reel/2" do
    test "likes and unlikes a reel" do
      user = create_user()
      reel = create_reel(user)

      refute Reels.liked_by?(user.id, reel.id)

      {:ok, _like} = Reels.like_reel(user.id, reel.id)
      assert Reels.liked_by?(user.id, reel.id)

      updated = Repo.get!(Reel, reel.id)
      assert updated.likes_count == 1

      {:ok, :ok} = Reels.unlike_reel(user.id, reel.id)
      refute Reels.liked_by?(user.id, reel.id)

      updated2 = Repo.get!(Reel, reel.id)
      assert updated2.likes_count == 0
    end
  end

  describe "liked_by?/2" do
    test "returns false when not liked" do
      user = create_user()
      reel = create_reel(user)
      refute Reels.liked_by?(user.id, reel.id)
    end

    test "returns true when liked" do
      user = create_user()
      reel = create_reel(user)
      {:ok, _} = Reels.like_reel(user.id, reel.id)
      assert Reels.liked_by?(user.id, reel.id)
    end
  end
end
