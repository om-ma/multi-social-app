defmodule SocialApp.Social.Follow do
  use Ecto.Schema
  import Ecto.Changeset

  schema "follows" do
    belongs_to :follower, SocialApp.Accounts.User
    belongs_to :following, SocialApp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(follow, attrs) do
    follow
    |> cast(attrs, [:follower_id, :following_id])
    |> validate_required([:follower_id, :following_id])
    |> unique_constraint([:follower_id, :following_id])
    |> foreign_key_constraint(:follower_id)
    |> foreign_key_constraint(:following_id)
  end
end
