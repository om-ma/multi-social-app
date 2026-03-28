defmodule SocialAppWeb.Components.PostCard do
  use Phoenix.Component

  attr :post, :map, required: true
  attr :liked, :boolean, default: false

  def post_card(assigns) do
    ~H"""
    <div class="bg-sa-surface rounded-2xl p-4 mb-4 border border-sa-border">
      <%!-- Header: avatar, name, username, time --%>
      <div class="flex items-center gap-3 rtl:flex-row-reverse mb-3">
        <div class="w-10 h-10 rounded-full bg-sa-surface2 flex items-center justify-center text-lg overflow-hidden shrink-0">
          <%= if @post.user.avatar_url do %>
            <img src={@post.user.avatar_url} alt="" class="w-full h-full object-cover" />
          <% else %>
            <span class="text-sa-green">
              {String.first(@post.user.display_name || @post.user.username)}
            </span>
          <% end %>
        </div>
        <div class="flex-1 min-w-0">
          <div class="flex items-center gap-2 rtl:flex-row-reverse">
            <span class="font-['Sora'] font-semibold text-sa-white text-sm truncate">
              {@post.user.display_name || @post.user.username}
            </span>
            <span class="text-sa-gray text-xs">
              @{@post.user.username}
            </span>
          </div>
          <p class="text-sa-gray text-xs mt-0.5">{time_ago(@post.inserted_at)}</p>
        </div>
        <button class="text-sa-gray hover:text-sa-white p-1">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="w-5 h-5"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M12 5v.01M12 12v.01M12 19v.01"
            />
          </svg>
        </button>
      </div>

      <%!-- Content --%>
      <%= if @post.content do %>
        <p class="text-sa-white font-['DM_Sans'] text-sm leading-relaxed mb-3 rtl:text-right">
          {@post.content}
        </p>
      <% end %>

      <%!-- Media placeholder --%>
      <%= if @post.media_url do %>
        <div class="w-full h-48 bg-sa-surface2 rounded-xl mb-3 flex items-center justify-center border border-sa-border">
          <div class="text-center text-sa-gray">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="w-8 h-8 mx-auto mb-1"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="1.5"
                d="M2.25 15.75l5.159-5.159a2.25 2.25 0 013.182 0l5.159 5.159m-1.5-1.5l1.409-1.409a2.25 2.25 0 013.182 0l2.909 2.909M3.75 21h16.5A2.25 2.25 0 0024 18.75V5.25A2.25 2.25 0 0021.75 3H3.75A2.25 2.25 0 001.5 5.25v13.5A2.25 2.25 0 003.75 21z"
              />
            </svg>
            <span class="text-xs">{@post.media_type || "media"}</span>
          </div>
        </div>
      <% end %>

      <%!-- Action bar --%>
      <div class="flex items-center gap-1 rtl:flex-row-reverse pt-2 border-t border-sa-border">
        <%!-- Like --%>
        <button
          phx-click="toggle_like"
          phx-value-post-id={@post.id}
          class={"flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm transition-colors " <>
            if(@liked, do: "text-sa-red", else: "text-sa-gray hover:text-sa-red")}
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="w-5 h-5"
            fill={if @liked, do: "currentColor", else: "none"}
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="1.5"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z"
            />
          </svg>
          <span>{@post.likes_count}</span>
        </button>

        <%!-- Comment --%>
        <button class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm text-sa-gray hover:text-sa-blue transition-colors">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="w-5 h-5"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="1.5"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M12 20.25c4.97 0 9-3.694 9-8.25s-4.03-8.25-9-8.25S3 7.444 3 12c0 2.104.859 4.023 2.273 5.48.432.447.74 1.04.586 1.641a4.483 4.483 0 01-.923 1.785A5.969 5.969 0 006 21c1.282 0 2.47-.402 3.445-1.087.81.22 1.668.337 2.555.337z"
            />
          </svg>
          <span>{@post.comments_count}</span>
        </button>

        <%!-- Share --%>
        <button class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm text-sa-gray hover:text-sa-green transition-colors">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="w-5 h-5"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="1.5"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M7.217 10.907a2.25 2.25 0 100 2.186m0-2.186c.18.324.283.696.283 1.093s-.103.77-.283 1.093m0-2.186l9.566-5.314m-9.566 7.5l9.566 5.314m0-12.814a2.25 2.25 0 103.935 2.186 2.25 2.25 0 00-3.935-2.186zm0 12.814a2.25 2.25 0 103.933-2.185 2.25 2.25 0 00-3.933 2.185z"
            />
          </svg>
        </button>

        <div class="flex-1"></div>

        <%!-- Save --%>
        <button class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm text-sa-gray hover:text-sa-gold transition-colors">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="w-5 h-5"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="1.5"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M17.593 3.322c1.1.128 1.907 1.077 1.907 2.185V21L12 17.25 4.5 21V5.507c0-1.108.806-2.057 1.907-2.185a48.507 48.507 0 0111.186 0z"
            />
          </svg>
        </button>
      </div>
    </div>
    """
  end

  defp time_ago(datetime) do
    diff = DateTime.diff(DateTime.utc_now(), datetime, :second)

    cond do
      diff < 60 -> "just now"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      diff < 604_800 -> "#{div(diff, 86400)}d ago"
      true -> Calendar.strftime(datetime, "%b %d")
    end
  end
end
