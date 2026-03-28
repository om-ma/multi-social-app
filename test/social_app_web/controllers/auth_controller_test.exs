defmodule SocialAppWeb.AuthControllerTest do
  use SocialAppWeb.ConnCase, async: true

  alias SocialApp.Accounts

  @valid_user %{
    "username" => "testuser",
    "email" => "test@example.com",
    "display_name" => "Test User",
    "password" => "password123"
  }

  describe "GET /login" do
    test "renders login page", %{conn: conn} do
      conn = get(conn, ~p"/login")
      assert html_response(conn, 200) =~ "Sign in"
    end
  end

  describe "GET /register" do
    test "renders register page", %{conn: conn} do
      conn = get(conn, ~p"/register")
      assert html_response(conn, 200) =~ "Create your account"
    end
  end

  describe "POST /register" do
    test "registers user and redirects to feed", %{conn: conn} do
      conn = post(conn, ~p"/register", user: @valid_user)
      assert redirected_to(conn) == ~p"/feed"
      assert get_session(conn, :user_id) != nil
    end

    test "re-renders form with invalid data", %{conn: conn} do
      conn = post(conn, ~p"/register", user: %{"username" => "", "email" => "", "password" => ""})
      assert html_response(conn, 200) =~ "Create your account"
    end

    test "rejects duplicate username", %{conn: conn} do
      {:ok, _} = Accounts.register_user(@valid_user)
      conn = post(conn, ~p"/register", user: %{@valid_user | "email" => "other@example.com"})
      assert html_response(conn, 200) =~ "has already been taken"
    end
  end

  describe "POST /login" do
    setup do
      {:ok, user} = Accounts.register_user(@valid_user)
      %{user: user}
    end

    test "logs in with valid credentials and redirects to feed", %{conn: conn} do
      conn = post(conn, ~p"/login", email: "test@example.com", password: "password123")
      assert redirected_to(conn) == ~p"/feed"
      assert get_session(conn, :user_id) != nil
    end

    test "shows error with invalid password", %{conn: conn} do
      conn = post(conn, ~p"/login", email: "test@example.com", password: "wrong")
      assert html_response(conn, 200) =~ "Invalid email or password"
    end

    test "shows error with non-existent email", %{conn: conn} do
      conn = post(conn, ~p"/login", email: "nobody@example.com", password: "password123")
      assert html_response(conn, 200) =~ "Invalid email or password"
    end
  end

  describe "GET /logout" do
    test "clears session and redirects to login", %{conn: conn} do
      {:ok, user} = Accounts.register_user(@valid_user)

      conn =
        conn
        |> init_test_session(%{user_id: user.id})
        |> get(~p"/logout")

      assert redirected_to(conn) == ~p"/login"
    end
  end
end
