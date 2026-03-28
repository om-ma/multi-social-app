defmodule SocialAppWeb.MessagingLive do
  use SocialAppWeb, :live_view

  alias SocialApp.Messaging

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    conversations = Messaging.list_conversations(user.id)
    unread = Messaging.unread_count(user.id)

    {:ok,
     assign(socket,
       conversations: conversations,
       unread_total: unread,
       page_title: "Messages"
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-sa-black">
      <div class="max-w-2xl mx-auto px-4 py-6">
        <%!-- Header --%>
        <div class="flex items-center justify-between mb-6">
          <h1 class="text-2xl font-['Sora'] font-bold text-sa-white">Messages</h1>
          <span
            :if={@unread_total > 0}
            class="bg-sa-green text-sa-white text-xs font-bold px-2 py-1 rounded-full"
          >
            {@unread_total}
          </span>
        </div>

        <%!-- Conversation List --%>
        <div class="space-y-1">
          <div
            :for={conv <- @conversations}
            class="flex items-center gap-3 p-3 rounded-xl bg-sa-surface hover:bg-sa-surface2 transition-colors cursor-pointer"
            phx-click={JS.navigate(~p"/messages/#{conv.id}")}
          >
            <%!-- Avatar --%>
            <div class="relative flex-shrink-0">
              <div class="w-12 h-12 rounded-full bg-sa-surface3 flex items-center justify-center overflow-hidden">
                <img
                  :if={conversation_avatar(conv, @current_user)}
                  src={conversation_avatar(conv, @current_user)}
                  class="w-12 h-12 rounded-full object-cover"
                />
                <span
                  :if={!conversation_avatar(conv, @current_user)}
                  class="text-sa-gray text-lg font-['Sora'] font-bold"
                >
                  {conversation_initials(conv, @current_user)}
                </span>
              </div>
            </div>

            <%!-- Content --%>
            <div class="flex-1 min-w-0">
              <div class="flex items-center justify-between">
                <p class="text-sm font-['Sora'] font-semibold text-sa-white truncate">
                  {conversation_name(conv, @current_user)}
                </p>
                <span
                  :if={conv.last_message}
                  class="text-xs text-sa-gray flex-shrink-0 ml-2"
                >
                  {format_time(conv.last_message.inserted_at)}
                </span>
              </div>
              <p
                :if={conv.last_message}
                class="text-sm text-sa-gray truncate mt-0.5"
              >
                <span :if={conv.is_group && conv.last_message.sender}>
                  {conv.last_message.sender.display_name || conv.last_message.sender.username}:
                </span>
                {conv.last_message.body || "Sent an image"}
              </p>
              <p :if={!conv.last_message} class="text-sm text-sa-gray mt-0.5">
                No messages yet
              </p>
            </div>
          </div>
        </div>

        <div
          :if={@conversations == []}
          class="text-center py-20 text-sa-gray"
        >
          <p class="text-lg font-['Sora']">No conversations yet</p>
          <p class="text-sm mt-2">Start a conversation to begin messaging</p>
        </div>
      </div>
    </div>
    """
  end

  defp conversation_name(conv, current_user) do
    if conv.is_group do
      conv.name || "Group Chat"
    else
      other = other_member(conv, current_user)
      if other, do: other.user.display_name || other.user.username, else: "Unknown"
    end
  end

  defp conversation_avatar(conv, current_user) do
    if conv.is_group do
      conv.avatar_url
    else
      other = other_member(conv, current_user)
      if other, do: other.user.avatar_url, else: nil
    end
  end

  defp conversation_initials(conv, current_user) do
    name = conversation_name(conv, current_user)

    name
    |> String.split(" ")
    |> Enum.take(2)
    |> Enum.map(&String.first/1)
    |> Enum.join()
    |> String.upcase()
  end

  defp other_member(conv, current_user) do
    Enum.find(conv.members, fn m -> m.user_id != current_user.id end)
  end

  defp format_time(nil), do: ""

  defp format_time(dt) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, dt, :second)

    cond do
      diff < 60 -> "now"
      diff < 3600 -> "#{div(diff, 60)}m"
      diff < 86_400 -> "#{div(diff, 3600)}h"
      diff < 604_800 -> "#{div(diff, 86_400)}d"
      true -> Calendar.strftime(dt, "%b %d")
    end
  end
end
