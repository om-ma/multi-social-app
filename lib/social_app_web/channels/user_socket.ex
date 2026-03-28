defmodule SocialAppWeb.UserSocket do
  use Phoenix.Socket

  channel "conversation:*", SocialAppWeb.ConversationChannel

  @impl true
  def connect(%{"user_id" => user_id}, socket, _connect_info) do
    {:ok, assign(socket, :user_id, String.to_integer(user_id))}
  end

  def connect(_params, _socket, _connect_info) do
    :error
  end

  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.user_id}"
end
