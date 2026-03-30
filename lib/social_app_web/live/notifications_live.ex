defmodule SocialAppWeb.NotificationsLive do
  use SocialAppWeb, :live_view

  alias SocialApp.Social

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id
    notifications = Social.list_notifications(user_id)

    # Mark all as read on open
    Social.mark_notifications_read(user_id)

    {:ok,
     socket
     |> assign(:page_title, "Notifications")
     |> assign(:notifications, notifications)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-[680px] mx-auto min-h-screen bg-sa-black">
      <div class="max-w-2xl mx-auto px-4 py-6">
        <h1 class="text-2xl font-bold font-['Sora'] text-sa-white mb-6">Notifications</h1>

        <%= if @notifications == [] do %>
          <p class="text-center text-sa-gray font-['DM_Sans'] py-12">No notifications yet</p>
        <% else %>
          <div class="space-y-1">
            <%= for notif <- @notifications do %>
              <div class={"flex items-start gap-3 p-3 rounded-lg rtl:flex-row-reverse #{if notif.read_at, do: "opacity-60", else: "bg-sa-surface"}"}>
                <%!-- Actor avatar --%>
                <.link navigate={~p"/u/#{notif.actor.username}"} class="flex-shrink-0">
                  <div class="w-10 h-10 rounded-full bg-sa-surface2 overflow-hidden">
                    <%= if notif.actor.avatar_url do %>
                      <img
                        src={notif.actor.avatar_url}
                        alt={notif.actor.username}
                        class="w-full h-full object-cover"
                      />
                    <% else %>
                      <div class="w-full h-full flex items-center justify-center text-sm text-sa-green font-['Sora']">
                        {String.first(notif.actor.username) |> String.upcase()}
                      </div>
                    <% end %>
                  </div>
                </.link>

                <div class="flex-1 min-w-0">
                  <p class="text-sm text-sa-white font-['DM_Sans']">
                    <.link navigate={~p"/u/#{notif.actor.username}"} class="font-bold hover:underline">
                      {notif.actor.display_name || notif.actor.username}
                    </.link>
                    <span class="text-sa-gray-light">
                      {notification_text(notif.type)}
                    </span>
                  </p>
                  <p class="text-xs text-sa-gray mt-0.5">
                    {format_time(notif.inserted_at)}
                  </p>
                </div>

                <div class="flex-shrink-0 mt-1">
                  {notification_icon(notif.type)}
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp notification_text("follow"), do: "started following you"
  defp notification_text("like"), do: "liked your post"
  defp notification_text("comment"), do: "commented on your post"
  defp notification_text("mention"), do: "mentioned you"
  defp notification_text("message"), do: "sent you a message"
  defp notification_text(_), do: "interacted with you"

  defp notification_icon("follow") do
    Phoenix.HTML.raw(~s(<span class="hero-user-plus-mini w-5 h-5 text-sa-green"></span>))
  end

  defp notification_icon("like") do
    Phoenix.HTML.raw(~s(<span class="hero-heart-mini w-5 h-5 text-sa-red"></span>))
  end

  defp notification_icon("comment") do
    Phoenix.HTML.raw(~s(<span class="hero-chat-bubble-left-mini w-5 h-5 text-sa-blue"></span>))
  end

  defp notification_icon(_) do
    Phoenix.HTML.raw(~s(<span class="hero-bell-mini w-5 h-5 text-sa-gold"></span>))
  end

  defp format_time(datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> "just now"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      diff < 604_800 -> "#{div(diff, 86400)}d ago"
      true -> Calendar.strftime(datetime, "%b %d")
    end
  end
end
