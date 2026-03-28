defmodule SocialAppWeb.Features.AuthTest do
  use SocialAppWeb.FeatureCase, async: false

  describe "registration" do
    test "register new user and land on /feed", %{session: session} do
      username = "newuser_#{System.unique_integer([:positive])}"
      email = "new_#{System.unique_integer([:positive])}@example.com"

      session
      |> visit("/register")
      |> assert_has(css("h1", text: "SocialApp"))
      |> assert_has(css("p", text: "Create your account"))
      |> fill_in(css("input[name='user[username]']"), with: username)
      |> fill_in(css("input[name='user[email]']"), with: email)
      |> fill_in(css("input[name='user[display_name]']"), with: "New User")
      |> fill_in(css("input[name='user[password]']"), with: "password123")
      |> click(button("Create Account"))
      |> assert_has(css("h1", text: "Feed"))
    end

    test "register with duplicate email shows error", %{session: session} do
      user = create_test_user()

      session
      |> visit("/register")
      |> fill_in(css("input[name='user[username]']"),
        with: "unique_user_#{System.unique_integer([:positive])}"
      )
      |> fill_in(css("input[name='user[email]']"), with: user.email)
      |> fill_in(css("input[name='user[display_name]']"), with: "Dup User")
      |> fill_in(css("input[name='user[password]']"), with: "password123")
      |> click(button("Create Account"))
      |> assert_has(css("p.text-\\[\\#E05050\\]"))
    end

    test "register with short password shows validation error", %{session: session} do
      session
      |> visit("/register")
      |> fill_in(css("input[name='user[username]']"),
        with: "shortpw_#{System.unique_integer([:positive])}"
      )
      |> fill_in(css("input[name='user[email]']"),
        with: "short_#{System.unique_integer([:positive])}@example.com"
      )
      |> fill_in(css("input[name='user[password]']"), with: "abc")
      |> click(button("Create Account"))
      |> assert_has(css("p.text-\\[\\#E05050\\]"))
    end
  end

  describe "login" do
    test "login with valid credentials and land on /feed", %{session: session} do
      user = create_test_user()

      session
      |> visit("/login")
      |> assert_has(css("p", text: "Sign in to your account"))
      |> fill_in(css("input[name='email']"), with: user.email)
      |> fill_in(css("input[name='password']"), with: "password123")
      |> click(button("Sign In"))
      |> assert_has(css("h1", text: "Feed"))
    end

    test "login with wrong password shows error", %{session: session} do
      user = create_test_user()

      session
      |> visit("/login")
      |> fill_in(css("input[name='email']"), with: user.email)
      |> fill_in(css("input[name='password']"), with: "wrongpassword")
      |> click(button("Sign In"))
      |> assert_has(css("div.mb-4", text: "Invalid email or password"))
    end
  end

  describe "logout" do
    test "logout redirects to /login", %{session: session} do
      user = create_test_user()

      session
      |> login(user)
      |> visit("/logout")
      |> assert_has(css("p", text: "Sign in to your account"))
    end
  end

  describe "access control" do
    test "access /feed without login redirects to /login", %{session: session} do
      session
      |> visit("/feed")
      |> assert_has(css("p", text: "Sign in to your account"))
    end
  end
end
