defmodule SocialAppWeb.PageControllerTest do
  use SocialAppWeb.ConnCase

  test "GET / redirects to /feed", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn, 302) == "/feed"
  end
end
