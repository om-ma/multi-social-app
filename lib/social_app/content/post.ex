defmodule SocialApp.Content.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    belongs_to :user, SocialApp.Accounts.User
    field :content, :string
    field :media_url, :string
    field :media_type, :string
    field :likes_count, :integer, default: 0
    field :comments_count, :integer, default: 0
    field :score, :float, default: 0.0

    timestamps(type: :utc_datetime)
  end

  def changeset(post, attrs) do
    post
    |> cast(attrs, [
      :user_id,
      :content,
      :media_url,
      :media_type,
      :likes_count,
      :comments_count,
      :score
    ])
    |> validate_required([:user_id])
    |> foreign_key_constraint(:user_id)
  end
end
