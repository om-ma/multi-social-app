defmodule SocialApp.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :conversation_id, references(:conversations, on_delete: :delete_all), null: false
      add :sender_id, references(:users, on_delete: :delete_all), null: false
      add :body, :text
      add :media_url, :string
      add :read_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:messages, [:conversation_id])
    create index(:messages, [:sender_id])
    create index(:messages, [:inserted_at])
  end
end
