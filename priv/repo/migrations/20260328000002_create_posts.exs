defmodule SocialApp.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :content, :text
      add :media_url, :string
      add :media_type, :string
      add :likes_count, :integer, default: 0
      add :comments_count, :integer, default: 0
      add :score, :float, default: 0.0

      timestamps(type: :utc_datetime)
    end

    create index(:posts, [:user_id])
    create index(:posts, [:score])
    create index(:posts, [:inserted_at])
  end
end
