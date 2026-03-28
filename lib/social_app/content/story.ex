defmodule SocialApp.Content.Story do
  use Ecto.Schema
  import Ecto.Changeset

  schema "stories" do
    belongs_to :user, SocialApp.Accounts.User
    field :media_url, :string
    field :expires_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  def changeset(story, attrs) do
    story
    |> cast(attrs, [:user_id, :media_url, :expires_at])
    |> validate_required([:user_id, :media_url, :expires_at])
    |> foreign_key_constraint(:user_id)
  end
end
