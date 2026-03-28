defmodule SocialApp.Reels do
  @moduledoc """
  Context for Reels / Short Videos.
  """

  import Ecto.Query
  alias SocialApp.Repo
  alias SocialApp.Content.Reel
  alias SocialApp.Content.ReelLike
  alias SocialApp.Social.Follow

  @default_page_size 10

  @doc """
  Lists reels ordered by score descending, with pagination.
  Options: :page (default 1), :page_size (default 10).
  """
  def list_reels(opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    page_size = Keyword.get(opts, :page_size, @default_page_size)
    offset = (page - 1) * page_size

    Reel
    |> order_by(desc: :score)
    |> limit(^page_size)
    |> offset(^offset)
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  Lists reels from users the current user follows, ordered by score desc, paginated.
  """
  def list_following_reels(user_id, opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    page_size = Keyword.get(opts, :page_size, @default_page_size)
    offset = (page - 1) * page_size

    following_ids =
      Follow
      |> where([f], f.follower_id == ^user_id)
      |> select([f], f.following_id)

    Reel
    |> where([r], r.user_id in subquery(following_ids))
    |> order_by(desc: :score)
    |> limit(^page_size)
    |> offset(^offset)
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  Gets a single reel with preloaded user.
  Raises if not found.
  """
  def get_reel!(id) do
    Reel
    |> Repo.get!(id)
    |> Repo.preload(:user)
  end

  @doc """
  Creates a reel for the given user.
  """
  def create_reel(user, attrs) do
    %Reel{}
    |> Reel.changeset(Map.put(attrs, "user_id", user.id))
    |> Repo.insert()
  end

  @doc """
  Increments the views_count of a reel.
  """
  def increment_views(%Reel{} = reel) do
    {1, [updated]} =
      Reel
      |> where(id: ^reel.id)
      |> select([r], r)
      |> Repo.update_all(inc: [views_count: 1])

    {:ok, Repo.preload(updated, :user)}
  end

  @doc """
  Recalculates score using: (likes*3)+(comments*2)+(views*1)-(hours_old*0.5)
  """
  def recalculate_score(%Reel{} = reel) do
    reel = Repo.reload!(reel)
    hours_old = DateTime.diff(DateTime.utc_now(), reel.inserted_at, :second) / 3600.0

    score =
      reel.likes_count * 3 +
        reel.comments_count * 2 +
        reel.views_count * 1 -
        hours_old * 0.5

    reel
    |> Ecto.Changeset.change(score: score)
    |> Repo.update()
  end

  @doc """
  Like a reel. Creates a ReelLike and increments likes_count.
  Returns {:ok, reel_like} or {:error, changeset}.
  """
  def like_reel(user_id, reel_id) do
    Repo.transaction(fn ->
      reel_like =
        %ReelLike{}
        |> ReelLike.changeset(%{user_id: user_id, reel_id: reel_id})
        |> Repo.insert!()

      Reel
      |> where(id: ^reel_id)
      |> Repo.update_all(inc: [likes_count: 1])

      reel_like
    end)
  end

  @doc """
  Unlike a reel. Deletes the ReelLike and decrements likes_count.
  """
  def unlike_reel(user_id, reel_id) do
    Repo.transaction(fn ->
      reel_like = Repo.get_by!(ReelLike, user_id: user_id, reel_id: reel_id)
      Repo.delete!(reel_like)

      Reel
      |> where(id: ^reel_id)
      |> Repo.update_all(inc: [likes_count: -1])

      :ok
    end)
  end

  @doc """
  Checks if a user has liked a reel.
  """
  def liked_by?(user_id, reel_id) do
    ReelLike
    |> where(user_id: ^user_id, reel_id: ^reel_id)
    |> Repo.exists?()
  end
end
