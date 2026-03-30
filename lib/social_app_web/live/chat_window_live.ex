defmodule SocialAppWeb.ChatWindowLive do
  use SocialAppWeb, :live_view

  alias SocialApp.Messaging

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    user = socket.assigns.current_user
    conversation = Messaging.get_conversation!(id, user.id)
    messages = Messaging.list_messages(conversation.id)

    if connected?(socket) do
      Messaging.subscribe_conversation(conversation.id)
      Messaging.mark_as_read(conversation.id, user.id)
    end

    {:ok,
     assign(socket,
       conversation: conversation,
       messages: messages,
       message_body: "",
       typing_users: MapSet.new(),
       page_title: conversation_title(conversation, user)
     )}
  end

  @impl true
  def handle_event("send_message", %{"body" => body}, socket) do
    body = String.trim(body)

    if body == "" do
      {:noreply, socket}
    else
      user = socket.assigns.current_user
      conv = socket.assigns.conversation

      case Messaging.send_message(conv.id, user.id, %{"body" => body}) do
        {:ok, _message} ->
          {:noreply, assign(socket, message_body: "")}

        {:error, _} ->
          {:noreply, socket}
      end
    end
  end

  @impl true
  def handle_event("send_image", %{"media_url" => url}, socket) do
    user = socket.assigns.current_user
    conv = socket.assigns.conversation
    Messaging.send_message(conv.id, user.id, %{"media_url" => url})
    {:noreply, socket}
  end

  @impl true
  def handle_event("typing", _params, socket) do
    Messaging.broadcast_typing(socket.assigns.conversation.id, socket.assigns.current_user)
    {:noreply, socket}
  end

  @impl true
  def handle_event("stop_typing", _params, socket) do
    Messaging.broadcast_stop_typing(socket.assigns.conversation.id, socket.assigns.current_user)
    {:noreply, socket}
  end

  @impl true
  def handle_event("update_body", %{"value" => value}, socket) do
    {:noreply, assign(socket, message_body: value)}
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    user = socket.assigns.current_user

    if message.sender_id != user.id do
      Messaging.mark_as_read(socket.assigns.conversation.id, user.id)
    end

    {:noreply, assign(socket, messages: socket.assigns.messages ++ [message])}
  end

  @impl true
  def handle_info({:typing, typer}, socket) do
    if typer.id != socket.assigns.current_user.id do
      typing_users = MapSet.put(socket.assigns.typing_users, typer.id)

      Process.send_after(self(), {:clear_typing, typer.id}, 3000)
      {:noreply, assign(socket, typing_users: typing_users)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:stop_typing, typer}, socket) do
    typing_users = MapSet.delete(socket.assigns.typing_users, typer.id)
    {:noreply, assign(socket, typing_users: typing_users)}
  end

  @impl true
  def handle_info({:clear_typing, user_id}, socket) do
    typing_users = MapSet.delete(socket.assigns.typing_users, user_id)
    {:noreply, assign(socket, typing_users: typing_users)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-[680px] mx-auto min-h-screen bg-sa-black flex flex-col" id="chat-window">
      <%!-- Header --%>
      <div class="sticky top-0 z-10 bg-sa-surface border-b border-sa-border px-4 py-3">
        <div class="max-w-2xl mx-auto flex items-center gap-3">
          <button
            phx-click={JS.navigate(~p"/messages")}
            class="text-sa-gray hover:text-sa-white transition-colors"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-6 w-6 rtl:rotate-180"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M15 19l-7-7 7-7"
              />
            </svg>
          </button>

          <div class="w-10 h-10 rounded-full bg-sa-surface3 flex items-center justify-center overflow-hidden flex-shrink-0">
            <img
              :if={header_avatar(@conversation, @current_user)}
              src={header_avatar(@conversation, @current_user)}
              class="w-10 h-10 rounded-full object-cover"
            />
            <span
              :if={!header_avatar(@conversation, @current_user)}
              class="text-sa-gray text-sm font-['Sora'] font-bold"
            >
              {header_initials(@conversation, @current_user)}
            </span>
          </div>

          <div class="flex-1 min-w-0">
            <p class="text-sm font-['Sora'] font-semibold text-sa-white truncate">
              {conversation_title(@conversation, @current_user)}
            </p>
            <p :if={@conversation.is_group} class="text-xs text-sa-gray truncate">
              {member_names(@conversation)}
            </p>
          </div>
        </div>
      </div>

      <%!-- Messages --%>
      <div
        class="flex-1 overflow-y-auto px-4 py-4"
        id="messages-container"
        phx-hook="ScrollBottom"
      >
        <div class="max-w-2xl mx-auto space-y-2">
          <div
            :for={msg <- @messages}
            class={[
              "flex",
              if(msg.sender_id == @current_user.id,
                do: "justify-end rtl:justify-start",
                else: "justify-start rtl:justify-end"
              )
            ]}
          >
            <div class={[
              "max-w-[75%] rounded-2xl px-4 py-2",
              if(msg.sender_id == @current_user.id,
                do: "bg-sa-green text-sa-white rounded-br-sm rtl:rounded-br-2xl rtl:rounded-bl-sm",
                else: "bg-sa-surface text-sa-white rounded-bl-sm rtl:rounded-bl-2xl rtl:rounded-br-sm"
              )
            ]}>
              <%!-- Sender name for group chats --%>
              <p
                :if={@conversation.is_group && msg.sender_id != @current_user.id}
                class="text-xs font-['Sora'] font-semibold text-sa-green-light mb-1"
              >
                {msg.sender.display_name || msg.sender.username}
              </p>

              <%!-- Image --%>
              <img
                :if={msg.media_url}
                src={msg.media_url}
                class="max-w-full rounded-lg mb-1"
                loading="lazy"
              />

              <%!-- Body --%>
              <p :if={msg.body} class="text-sm font-['DM_Sans'] break-words">{msg.body}</p>

              <%!-- Time + read receipt --%>
              <div class="flex items-center gap-1 mt-1 justify-end">
                <span class="text-[10px] opacity-60">
                  {Calendar.strftime(msg.inserted_at, "%H:%M")}
                </span>
                <span
                  :if={msg.sender_id == @current_user.id}
                  class={[
                    "text-[10px]",
                    if(msg.read_at, do: "text-sa-green-light", else: "opacity-40")
                  ]}
                >
                  {if msg.read_at, do: "✓✓", else: "✓"}
                </span>
              </div>
            </div>
          </div>

          <%!-- Typing indicator --%>
          <div
            :if={MapSet.size(@typing_users) > 0}
            class="flex justify-start rtl:justify-end"
          >
            <div class="bg-sa-surface text-sa-gray rounded-2xl px-4 py-2 text-sm italic">
              typing...
            </div>
          </div>
        </div>
      </div>

      <%!-- Input --%>
      <div class="sticky bottom-0 bg-sa-surface border-t border-sa-border px-4 py-3">
        <div class="max-w-2xl mx-auto">
          <form
            phx-submit="send_message"
            phx-change="update_body"
            class="flex items-center gap-2"
          >
            <input
              type="text"
              name="body"
              value={@message_body}
              placeholder="Type a message..."
              autocomplete="off"
              phx-keydown="typing"
              phx-key="*"
              phx-debounce="500"
              class="flex-1 bg-sa-surface2 text-sa-white placeholder-sa-gray rounded-xl px-4 py-2.5 text-sm font-['DM_Sans'] border border-sa-border focus:border-sa-green focus:ring-0 focus:outline-none"
            />
            <button
              type="submit"
              class="bg-sa-green hover:bg-sa-green-light text-sa-white rounded-xl px-4 py-2.5 transition-colors flex-shrink-0"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5 rtl:rotate-180"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path d="M10.894 2.553a1 1 0 00-1.788 0l-7 14a1 1 0 001.169 1.409l5-1.429A1 1 0 009 15.571V11a1 1 0 112 0v4.571a1 1 0 00.725.962l5 1.428a1 1 0 001.17-1.408l-7-14z" />
              </svg>
            </button>
          </form>
        </div>
      </div>
    </div>
    """
  end

  defp conversation_title(conv, current_user) do
    if conv.is_group do
      conv.name || "Group Chat"
    else
      other = Enum.find(conv.members, fn m -> m.user_id != current_user.id end)
      if other, do: other.user.display_name || other.user.username, else: "Unknown"
    end
  end

  defp header_avatar(conv, current_user) do
    if conv.is_group do
      conv.avatar_url
    else
      other = Enum.find(conv.members, fn m -> m.user_id != current_user.id end)
      if other, do: other.user.avatar_url, else: nil
    end
  end

  defp header_initials(conv, current_user) do
    name = conversation_title(conv, current_user)

    name
    |> String.split(" ")
    |> Enum.take(2)
    |> Enum.map(&String.first/1)
    |> Enum.join()
    |> String.upcase()
  end

  defp member_names(conv) do
    conv.members
    |> Enum.map(fn m -> m.user.display_name || m.user.username end)
    |> Enum.join(", ")
  end
end
