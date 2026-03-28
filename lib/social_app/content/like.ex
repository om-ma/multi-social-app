defmodule SocialApp.Content.Like do
  use Ecto.Schema
  import Ecto.Changeset

  schema "likes" do
    belongs_to :user, SocialApp.Accounts.User
    belongs_to :post, SocialApp.Content.Post

    timestamps(type: :utc_datetime)
  end

  def changeset(like, attrs) do
    like
    |> cast(attrs, [:user_id, :post_id])
    |> validate_required([:user_id, :post_id])
    |> unique_constraint([:user_id, :post_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:post_id)
  end
end
