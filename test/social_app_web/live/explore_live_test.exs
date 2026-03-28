defmodule SocialAppWeb.ExploreLiveTest do
  use SocialAppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias SocialApp.Repo

  defp create_user(attrs \\ %{}) do
    num = System.unique_integer([:positive])

    defaults = %{
      username: "user_#{num}",
      email: "user_#{num}@test.com",
      display_name: "User #{num}",
      password: "password123"
    }

    {:ok, user} =
      %SocialApp.Accounts.User{}
      |> SocialApp.Accounts.User.registration_changeset(Map.merge(defaults, attrs))
      |> Repo.insert()

    user
  end

  defp log_in(conn, user) do
    conn |> Plug.Test.init_test_session(%{user_id: user.id})
  end

  describe "mount" do
    test "redirects when not authenticated", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/login"}}} = live(conn, ~p"/explore")
    end

    test "renders explore page", %{conn: conn} do
      user = create_user()
      conn = log_in(conn, user)

      {:ok, _view, html} = live(conn, ~p"/explore")
      assert html =~ "Explore"
      assert html =~ "Search users"
    end

    test "shows suggested users", %{conn: conn} do
      user = create_user()
      _other = create_user(%{display_name: "Suggested Friend"})
      conn = log_in(conn, user)

      {:ok, _view, html} = live(conn, ~p"/explore")
      assert html =~ "Suggested Friend"
    end
  end

  describe "search" do
    test "searches users", %{conn: conn} do
      user = create_user()
      _target = create_user(%{username: "findme_user", display_name: "Find Me"})
      conn = log_in(conn, user)

      {:ok, view, _html} = live(conn, ~p"/explore")

      html =
        view
        |> element("form")
        |> render_change(%{query: "findme"})

      assert html =~ "Find Me"
      assert html =~ "Search Results"
    end

    test "shows no results message", %{conn: conn} do
      user = create_user()
      conn = log_in(conn, user)

      {:ok, view, _html} = live(conn, ~p"/explore")

      html =
        view
        |> element("form")
        |> render_change(%{query: "zzz_nonexistent_zzz"})

      assert html =~ "No users found"
    end
  end
end
