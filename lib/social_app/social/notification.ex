defmodule SocialApp.Social.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notifications" do
    belongs_to :user, SocialApp.Accounts.User
    belongs_to :actor, SocialApp.Accounts.User
    field :type, :string
    field :reference_id, :integer
    field :read_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:user_id, :actor_id, :type, :reference_id, :read_at])
    |> validate_required([:user_id, :actor_id, :type])
    |> validate_inclusion(:type, ["like", "follow", "comment", "mention", "message"])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:actor_id)
  end
end
