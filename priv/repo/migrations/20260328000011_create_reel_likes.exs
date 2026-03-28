defmodule SocialApp.Repo.Migrations.CreateReelLikes do
  use Ecto.Migration

  def change do
    create table(:reel_likes) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :reel_id, references(:reels, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:reel_likes, [:user_id, :reel_id])
    create index(:reel_likes, [:reel_id])
  end
end
