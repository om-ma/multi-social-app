defmodule SocialApp.Messaging.ConversationMember do
  use Ecto.Schema
  import Ecto.Changeset

  schema "conversation_members" do
    belongs_to :conversation, SocialApp.Messaging.Conversation
    belongs_to :user, SocialApp.Accounts.User
    field :joined_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  def changeset(member, attrs) do
    member
    |> cast(attrs, [:conversation_id, :user_id, :joined_at])
    |> validate_required([:conversation_id, :user_id])
    |> unique_constraint([:conversation_id, :user_id])
    |> foreign_key_constraint(:conversation_id)
    |> foreign_key_constraint(:user_id)
  end
end
