defmodule SocialAppWeb.Components.ReelItem do
  @moduledoc """
  Full-screen reel item component with overlays, sidebar actions, and user info.
  """
  use Phoenix.Component

  attr :reel, :map, required: true
  attr :liked, :boolean, default: false
  attr :current_user, :map, required: true

  def reel_item(assigns) do
    ~H"""
    <div class="reel-item snap-start relative w-full h-screen flex-shrink-0 bg-sa-black overflow-hidden">
      <%!-- Video / Thumbnail area --%>
      <div class="absolute inset-0 flex items-center justify-center bg-sa-surface">
        <%= if @reel.thumbnail_url do %>
          <img
            src={@reel.thumbnail_url}
            alt={@reel.caption || "Reel"}
            class="w-full h-full object-cover"
          />
        <% else %>
          <div class="text-sa-gray text-lg font-['DM_Sans']">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="w-16 h-16 mx-auto mb-2 opacity-40"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="1.5"
                d="M15.75 10.5l4.72-4.72a.75.75 0 011.28.53v11.38a.75.75 0 01-1.28.53l-4.72-4.72M4.5 18.75h9a2.25 2.25 0 002.25-2.25v-9a2.25 2.25 0 00-2.25-2.25h-9A2.25 2.25 0 002.25 7.5v9a2.25 2.25 0 002.25 2.25z"
              />
            </svg>
            Video
          </div>
        <% end %>
      </div>

      <%!-- Gradient overlay at bottom --%>
      <div class="absolute inset-x-0 bottom-0 h-64 bg-gradient-to-t from-sa-black/90 via-sa-black/40 to-transparent pointer-events-none">
      </div>

      <%!-- Bottom info: user + caption --%>
      <div class="absolute bottom-6 left-4 right-20 z-10">
        <div class="flex items-center gap-3 mb-3">
          <%= if @reel.user.avatar_url do %>
            <img
              src={@reel.user.avatar_url}
              alt={@reel.user.username}
              class="w-10 h-10 rounded-full border-2 border-sa-green object-cover"
            />
          <% else %>
            <div class="w-10 h-10 rounded-full border-2 border-sa-green bg-sa-surface2 flex items-center justify-center">
              <span class="text-sa-white text-sm font-bold font-['Sora']">
                {String.first(@reel.user.username)}
              </span>
            </div>
          <% end %>
          <div>
            <p class="text-sa-white text-sm font-bold font-['Sora']">
              {@reel.user.display_name || @reel.user.username}
            </p>
            <p class="text-sa-gray-light text-xs font-['DM_Sans']">
              @{@reel.user.username}
            </p>
          </div>
        </div>
        <%= if @reel.caption do %>
          <p class="text-sa-white text-sm font-['DM_Sans'] leading-relaxed line-clamp-2">
            {@reel.caption}
          </p>
        <% end %>
      </div>

      <%!-- Right sidebar actions --%>
      <div class="absolute right-3 bottom-28 z-10 flex flex-col items-center gap-5">
        <%!-- Like button --%>
        <button
          phx-click="toggle_like"
          phx-value-reel-id={@reel.id}
          class="flex flex-col items-center gap-1 group"
        >
          <div class={[
            "w-11 h-11 rounded-full flex items-center justify-center transition-all",
            if(@liked, do: "bg-sa-red/20", else: "bg-sa-white/10 backdrop-blur-sm")
          ]}>
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class={[
                "w-6 h-6 transition-colors",
                if(@liked, do: "text-sa-red fill-sa-red", else: "text-sa-white")
              ]}
              viewBox="0 0 24 24"
              fill={if @liked, do: "currentColor", else: "none"}
              stroke="currentColor"
              stroke-width="2"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z"
              />
            </svg>
          </div>
          <span class="text-sa-white text-xs font-['DM_Sans']">{@reel.likes_count}</span>
        </button>

        <%!-- Comments --%>
        <div class="flex flex-col items-center gap-1">
          <div class="w-11 h-11 rounded-full bg-sa-white/10 backdrop-blur-sm flex items-center justify-center">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="w-6 h-6 text-sa-white"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="2"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M12 20.25c4.97 0 9-3.694 9-8.25s-4.03-8.25-9-8.25S3 7.444 3 12c0 2.104.859 4.023 2.273 5.48.432.447.74 1.04.586 1.641a4.483 4.483 0 01-.923 1.785A5.969 5.969 0 006 21c1.282 0 2.47-.402 3.445-1.087.81.22 1.668.337 2.555.337z"
              />
            </svg>
          </div>
          <span class="text-sa-white text-xs font-['DM_Sans']">{@reel.comments_count}</span>
        </div>

        <%!-- Views --%>
        <div class="flex flex-col items-center gap-1">
          <div class="w-11 h-11 rounded-full bg-sa-white/10 backdrop-blur-sm flex items-center justify-center">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="w-6 h-6 text-sa-white"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="2"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z"
              />
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
              />
            </svg>
          </div>
          <span class="text-sa-white text-xs font-['DM_Sans']">{@reel.views_count}</span>
        </div>
      </div>
    </div>
    """
  end
end
