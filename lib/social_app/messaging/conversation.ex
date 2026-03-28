defmodule SocialApp.Messaging.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "conversations" do
    field :is_group, :boolean, default: false
    field :name, :string
    field :avatar_url, :string

    has_many :members, SocialApp.Messaging.ConversationMember
    has_many :messages, SocialApp.Messaging.Message

    timestamps(type: :utc_datetime)
  end

  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:is_group, :name, :avatar_url])
  end
end
