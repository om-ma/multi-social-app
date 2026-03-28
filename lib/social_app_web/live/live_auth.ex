defmodule SocialAppWeb.LiveAuth do
  import Phoenix.LiveView
  import Phoenix.Component

  def on_mount(:require_auth, _params, %{"user_id" => user_id}, socket) do
    user = SocialApp.Accounts.get_user!(user_id)
    {:cont, assign(socket, :current_user, user)}
  rescue
    Ecto.NoResultsError ->
      {:halt, redirect(socket, to: "/login")}
  end

  def on_mount(:require_auth, _params, _session, socket) do
    {:halt, redirect(socket, to: "/login")}
  end

  def on_mount(:maybe_auth, _params, %{"user_id" => user_id}, socket) do
    user = SocialApp.Accounts.get_user!(user_id)
    {:cont, assign(socket, :current_user, user)}
  rescue
    Ecto.NoResultsError ->
      {:cont, assign(socket, :current_user, nil)}
  end

  def on_mount(:maybe_auth, _params, _session, socket) do
    {:cont, assign(socket, :current_user, nil)}
  end
end
