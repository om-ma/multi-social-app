defmodule SocialApp.Content.Reel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "reels" do
    belongs_to :user, SocialApp.Accounts.User
    field :video_url, :string
    field :thumbnail_url, :string
    field :caption, :string
    field :views_count, :integer, default: 0
    field :likes_count, :integer, default: 0
    field :comments_count, :integer, default: 0
    field :score, :float, default: 0.0

    timestamps(type: :utc_datetime)
  end

  def changeset(reel, attrs) do
    reel
    |> cast(attrs, [
      :user_id,
      :video_url,
      :thumbnail_url,
      :caption,
      :views_count,
      :likes_count,
      :comments_count,
      :score
    ])
    |> validate_required([:user_id, :video_url])
    |> foreign_key_constraint(:user_id)
  end
end
