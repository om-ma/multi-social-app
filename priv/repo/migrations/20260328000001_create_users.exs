defmodule SocialApp.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:users) do
      add :username, :string, null: false
      add :email, :citext, null: false
      add :display_name, :string
      add :hashed_password, :string, null: false
      add :avatar_url, :string
      add :cover_url, :string
      add :bio, :text
      add :location, :string
      add :followers_count, :integer, default: 0
      add :following_count, :integer, default: 0
      add :posts_count, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:username])
    create unique_index(:users, [:email])
  end
end
