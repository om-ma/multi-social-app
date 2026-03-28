defmodule SocialApp.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations) do
      add :is_group, :boolean, default: false
      add :name, :string
      add :avatar_url, :string

      timestamps(type: :utc_datetime)
    end

    create table(:conversation_members) do
      add :conversation_id, references(:conversations, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :joined_at, :utc_datetime, default: fragment("now()")

      timestamps(type: :utc_datetime)
    end

    create unique_index(:conversation_members, [:conversation_id, :user_id])
    create index(:conversation_members, [:user_id])
  end
end
