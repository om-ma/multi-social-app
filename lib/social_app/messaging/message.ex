defmodule SocialApp.Messaging.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    belongs_to :conversation, SocialApp.Messaging.Conversation
    belongs_to :sender, SocialApp.Accounts.User
    field :body, :string
    field :media_url, :string
    field :read_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:conversation_id, :sender_id, :body, :media_url, :read_at])
    |> validate_required([:conversation_id, :sender_id])
    |> foreign_key_constraint(:conversation_id)
    |> foreign_key_constraint(:sender_id)
  end
end
