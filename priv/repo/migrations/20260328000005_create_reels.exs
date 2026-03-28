defmodule SocialApp.Repo.Migrations.CreateReels do
  use Ecto.Migration

  def change do
    create table(:reels) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :video_url, :string, null: false
      add :thumbnail_url, :string
      add :caption, :text
      add :views_count, :integer, default: 0
      add :likes_count, :integer, default: 0
      add :comments_count, :integer, default: 0
      add :score, :float, default: 0.0

      timestamps(type: :utc_datetime)
    end

    create index(:reels, [:user_id])
    create index(:reels, [:score])
    create index(:reels, [:inserted_at])
  end
end
