defmodule SocialAppWeb.ConversationChannel do
  use SocialAppWeb, :channel

  alias SocialApp.Messaging

  @impl true
  def join("conversation:" <> conversation_id, _payload, socket) do
    conversation_id = String.to_integer(conversation_id)
    user_id = socket.assigns.user_id

    try do
      _conv = Messaging.get_conversation!(conversation_id, user_id)
      socket = assign(socket, :conversation_id, conversation_id)
      {:ok, socket}
    rescue
      Ecto.NoResultsError ->
        {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in("new_message", %{"body" => body} = payload, socket) do
    attrs = %{"body" => body}

    attrs =
      case Map.get(payload, "media_url") do
        nil -> attrs
        url -> Map.put(attrs, "media_url", url)
      end

    case Messaging.send_message(
           socket.assigns.conversation_id,
           socket.assigns.user_id,
           attrs
         ) do
      {:ok, message} ->
        broadcast!(socket, "new_message", %{
          id: message.id,
          body: message.body,
          media_url: message.media_url,
          sender_id: message.sender_id,
          sender_username: message.sender.username,
          sender_display_name: message.sender.display_name,
          sender_avatar_url: message.sender.avatar_url,
          inserted_at: DateTime.to_iso8601(message.inserted_at)
        })

        {:reply, :ok, socket}

      {:error, _changeset} ->
        {:reply, {:error, %{reason: "failed to send"}}, socket}
    end
  end

  @impl true
  def handle_in("typing", _payload, socket) do
    broadcast_from!(socket, "typing", %{user_id: socket.assigns.user_id})
    {:noreply, socket}
  end

  @impl true
  def handle_in("stop_typing", _payload, socket) do
    broadcast_from!(socket, "stop_typing", %{user_id: socket.assigns.user_id})
    {:noreply, socket}
  end
end
