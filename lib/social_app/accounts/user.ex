defmodule SocialApp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :username, :string
    field :email, :string
    field :display_name, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :avatar_url, :string
    field :cover_url, :string
    field :bio, :string
    field :location, :string
    field :followers_count, :integer, default: 0
    field :following_count, :integer, default: 0
    field :posts_count, :integer, default: 0

    timestamps(type: :utc_datetime)
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :display_name, :password])
    |> validate_required([:username, :email, :password])
    |> validate_length(:username, min: 3, max: 30)
    |> validate_format(:username, ~r/^[a-zA-Z0-9._]+$/,
      message: "only letters, numbers, dots, and underscores"
    )
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> validate_length(:password, min: 6, max: 72)
    |> unique_constraint(:username)
    |> unique_constraint(:email)
    |> hash_password()
  end

  defp hash_password(changeset) do
    case get_change(changeset, :password) do
      nil ->
        changeset

      password ->
        changeset
        |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
        |> delete_change(:password)
    end
  end
end
