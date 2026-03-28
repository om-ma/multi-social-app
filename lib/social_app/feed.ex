defmodule SocialApp.Feed do
  @moduledoc """
  Context module for feed-related operations: posts, likes, and stories.
  """

  import Ecto.Query
  alias SocialApp.Repo
  alias SocialApp.Content.{Post, Like, Story}

  # ── Posts ──

  def list_feed_posts(opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)
    offset = Keyword.get(opts, :offset, 0)

    Post
    |> order_by([p], desc: p.inserted_at)
    |> limit(^limit)
    |> offset(^offset)
    |> preload(:user)
    |> Repo.all()
  end

  def get_post!(id) do
    Post
    |> Repo.get!(id)
    |> Repo.preload(:user)
  end

  def create_post(user_id, attrs) do
    %Post{}
    |> Post.changeset(Map.put(attrs, "user_id", user_id))
    |> Repo.insert()
    |> case do
      {:ok, post} -> {:ok, Repo.preload(post, :user)}
      error -> error
    end
  end

  def delete_post(%Post{} = post) do
    Repo.delete(post)
  end

  # ── Likes ──

  def like_post(user_id, post_id) do
    Repo.transaction(fn ->
      changeset = Like.changeset(%Like{}, %{user_id: user_id, post_id: post_id})

      case Repo.insert(changeset) do
        {:ok, like} ->
          {1, _} =
            from(p in Post, where: p.id == ^post_id)
            |> Repo.update_all(inc: [likes_count: 1])

          like

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  def unlike_post(user_id, post_id) do
    Repo.transaction(fn ->
      case Repo.get_by(Like, user_id: user_id, post_id: post_id) do
        nil ->
          Repo.rollback(:not_found)

        like ->
          Repo.delete!(like)

          from(p in Post, where: p.id == ^post_id)
          |> Repo.update_all(inc: [likes_count: -1])

          :ok
      end
    end)
  end

  def liked_by?(user_id, post_id) do
    from(l in Like, where: l.user_id == ^user_id and l.post_id == ^post_id)
    |> Repo.exists?()
  end

  def list_user_liked_post_ids(user_id, post_ids) when is_list(post_ids) do
    from(l in Like,
      where: l.user_id == ^user_id and l.post_id in ^post_ids,
      select: l.post_id
    )
    |> Repo.all()
    |> MapSet.new()
  end

  # ── Stories ──

  def list_active_stories do
    now = DateTime.utc_now()

    from(s in Story,
      where: s.expires_at > ^now,
      order_by: [asc: s.inserted_at],
      preload: :user
    )
    |> Repo.all()
    |> Enum.group_by(& &1.user_id)
  end

  def create_story(user_id, attrs) do
    expires_at =
      DateTime.utc_now()
      |> DateTime.add(24, :hour)
      |> DateTime.truncate(:second)

    %Story{}
    |> Story.changeset(
      attrs
      |> Map.put("user_id", user_id)
      |> Map.put("expires_at", expires_at)
    )
    |> Repo.insert()
  end
end
