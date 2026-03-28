defmodule SocialApp.Content.ReelLike do
  use Ecto.Schema
  import Ecto.Changeset

  schema "reel_likes" do
    belongs_to :user, SocialApp.Accounts.User
    belongs_to :reel, SocialApp.Content.Reel

    timestamps(type: :utc_datetime)
  end

  def changeset(reel_like, attrs) do
    reel_like
    |> cast(attrs, [:user_id, :reel_id])
    |> validate_required([:user_id, :reel_id])
    |> unique_constraint([:user_id, :reel_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:reel_id)
  end
end
