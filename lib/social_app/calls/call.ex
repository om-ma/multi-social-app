defmodule SocialApp.Calls.Call do
  use Ecto.Schema
  import Ecto.Changeset

  schema "calls" do
    belongs_to :caller, SocialApp.Accounts.User
    belongs_to :receiver, SocialApp.Accounts.User
    field :call_type, :string
    field :status, :string, default: "ringing"
    field :started_at, :utc_datetime
    field :ended_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  def changeset(call, attrs) do
    call
    |> cast(attrs, [:caller_id, :receiver_id, :call_type, :status, :started_at, :ended_at])
    |> validate_required([:caller_id, :receiver_id, :call_type])
    |> validate_inclusion(:call_type, ["video", "voice"])
    |> validate_inclusion(:status, ["ringing", "active", "ended", "declined"])
    |> foreign_key_constraint(:caller_id)
    |> foreign_key_constraint(:receiver_id)
  end
end
