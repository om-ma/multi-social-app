defmodule SocialAppWeb.AuthController do
  use SocialAppWeb, :controller

  alias SocialApp.Accounts

  def login_page(conn, _params) do
    render(conn, :login, error: nil)
  end

  def register_page(conn, _params) do
    changeset = Accounts.change_registration()
    render(conn, :register, changeset: changeset)
  end

  def login(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate(email, password) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> configure_session(renew: true)
        |> redirect(to: ~p"/feed")

      {:error, _} ->
        render(conn, :login, error: "Invalid email or password")
    end
  end

  def register(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> configure_session(renew: true)
        |> redirect(to: ~p"/feed")

      {:error, changeset} ->
        render(conn, :register, changeset: changeset)
    end
  end

  def logout(conn, _params) do
    conn
    |> clear_session()
    |> redirect(to: ~p"/login")
  end
end
