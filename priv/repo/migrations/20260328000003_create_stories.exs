defmodule SocialApp.Repo.Migrations.CreateStories do
  use Ecto.Migration

  def change do
    create table(:stories) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :media_url, :string, null: false
      add :expires_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:stories, [:user_id])
    create index(:stories, [:expires_at])
  end
end
