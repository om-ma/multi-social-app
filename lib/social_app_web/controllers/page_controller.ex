defmodule SocialAppWeb.PageController do
  use SocialAppWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
