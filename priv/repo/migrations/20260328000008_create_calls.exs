defmodule SocialApp.Repo.Migrations.CreateCalls do
  use Ecto.Migration

  def change do
    create table(:calls) do
      add :caller_id, references(:users, on_delete: :delete_all), null: false
      add :receiver_id, references(:users, on_delete: :delete_all), null: false
      add :call_type, :string, null: false
      add :status, :string, null: false, default: "ringing"
      add :started_at, :utc_datetime
      add :ended_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:calls, [:caller_id])
    create index(:calls, [:receiver_id])
  end
end
