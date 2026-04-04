defmodule SocialAppWeb.PageController do
  use SocialAppWeb, :controller

  def home(conn, _params) do
    redirect(conn, to: "/feed")
  end
end
