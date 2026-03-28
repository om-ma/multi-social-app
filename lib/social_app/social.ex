defmodule SocialApp.Social do
  @moduledoc """
  The Social context — follows, notifications, user discovery.
  """

  import Ecto.Query
  alias SocialApp.Repo
  alias SocialApp.Accounts.User
  alias SocialApp.Social.{Follow, Notification}

  # ── Follows ──────────────────────────────────────────────

  @doc "Follow a user. Increments counters and creates a notification."
  def follow(follower_id, following_id) when follower_id != following_id do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :follow,
      Follow.changeset(%Follow{}, %{
        follower_id: follower_id,
        following_id: following_id
      })
    )
    |> Ecto.Multi.update_all(
      :inc_following,
      fn _ ->
        from(u in User, where: u.id == ^follower_id)
      end,
      inc: [following_count: 1]
    )
    |> Ecto.Multi.update_all(
      :inc_followers,
      fn _ ->
        from(u in User, where: u.id == ^following_id)
      end,
      inc: [followers_count: 1]
    )
    |> Ecto.Multi.insert(:notification, fn _ ->
      Notification.changeset(%Notification{}, %{
        user_id: following_id,
        actor_id: follower_id,
        type: "follow"
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{follow: follow}} -> {:ok, follow}
      {:error, :follow, changeset, _} -> {:error, changeset}
      {:error, _, reason, _} -> {:error, reason}
    end
  end

  def follow(_, _), do: {:error, :cannot_follow_self}

  @doc "Unfollow a user. Decrements counters."
  def unfollow(follower_id, following_id) do
    case Repo.get_by(Follow, follower_id: follower_id, following_id: following_id) do
      nil ->
        {:error, :not_following}

      follow ->
        Ecto.Multi.new()
        |> Ecto.Multi.delete(:follow, follow)
        |> Ecto.Multi.update_all(
          :dec_following,
          fn _ ->
            from(u in User, where: u.id == ^follower_id and u.following_count > 0)
          end,
          inc: [following_count: -1]
        )
        |> Ecto.Multi.update_all(
          :dec_followers,
          fn _ ->
            from(u in User, where: u.id == ^following_id and u.followers_count > 0)
          end,
          inc: [followers_count: -1]
        )
        |> Repo.transaction()
        |> case do
          {:ok, _} -> :ok
          {:error, _, reason, _} -> {:error, reason}
        end
    end
  end

  @doc "Check if user A follows user B."
  def following?(follower_id, following_id) do
    Repo.exists?(
      from f in Follow, where: f.follower_id == ^follower_id and f.following_id == ^following_id
    )
  end

  @doc "List paginated followers of a user."
  def list_followers(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)

    from(f in Follow,
      where: f.following_id == ^user_id,
      join: u in User,
      on: u.id == f.follower_id,
      select: u,
      order_by: [desc: f.inserted_at],
      limit: ^limit,
      offset: ^offset
    )
    |> Repo.all()
  end

  @doc "List paginated users that a user follows."
  def list_following(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)

    from(f in Follow,
      where: f.follower_id == ^user_id,
      join: u in User,
      on: u.id == f.following_id,
      select: u,
      order_by: [desc: f.inserted_at],
      limit: ^limit,
      offset: ^offset
    )
    |> Repo.all()
  end

  # ── Notifications ───────────────────────────────────────

  @doc "List paginated notifications for a user, preloading actor."
  def list_notifications(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)

    from(n in Notification,
      where: n.user_id == ^user_id,
      order_by: [desc: n.inserted_at],
      preload: [:actor],
      limit: ^limit,
      offset: ^offset
    )
    |> Repo.all()
  end

  @doc "Mark all notifications as read for a user."
  def mark_notifications_read(user_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    from(n in Notification,
      where: n.user_id == ^user_id and is_nil(n.read_at)
    )
    |> Repo.update_all(set: [read_at: now])
  end

  @doc "Count unread notifications for a user."
  def unread_notification_count(user_id) do
    from(n in Notification,
      where: n.user_id == ^user_id and is_nil(n.read_at),
      select: count(n.id)
    )
    |> Repo.one()
  end

  # ── Discovery ───────────────────────────────────────────

  @doc "List suggested users not followed by the current user (excluding self)."
  def list_suggested_users(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)

    followed_ids =
      from(f in Follow, where: f.follower_id == ^user_id, select: f.following_id)

    from(u in User,
      where: u.id != ^user_id and u.id not in subquery(followed_ids),
      order_by: [desc: u.followers_count],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc "Search users by username or display_name (ILIKE)."
  def search_users(query) when is_binary(query) and byte_size(query) > 0 do
    pattern = "%#{query}%"

    from(u in User,
      where: ilike(u.username, ^pattern) or ilike(u.display_name, ^pattern),
      order_by: [asc: u.username],
      limit: 20
    )
    |> Repo.all()
  end

  def search_users(_), do: []
end
