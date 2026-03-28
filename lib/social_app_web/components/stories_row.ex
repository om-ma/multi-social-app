defmodule SocialAppWeb.Components.StoriesRow do
  use Phoenix.Component

  attr :stories_by_user, :map, default: %{}
  attr :current_user, :map, required: true

  def stories_row(assigns) do
    ~H"""
    <div class="mb-4">
      <div class="flex gap-4 overflow-x-auto pb-2 scrollbar-hide rtl:flex-row-reverse">
        <%!-- Your Story button --%>
        <button
          phx-click="open_create_story"
          class="flex flex-col items-center gap-1.5 shrink-0"
        >
          <div class="w-16 h-16 rounded-full border-2 border-dashed border-sa-green flex items-center justify-center bg-sa-surface">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="w-6 h-6 text-sa-green"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="2"
            >
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
            </svg>
          </div>
          <span class="text-xs text-sa-gray-light font-['DM_Sans']">Your Story</span>
        </button>

        <%!-- Other users' stories --%>
        <%= for {user_id, stories} <- @stories_by_user do %>
          <% user = List.first(stories).user %>
          <button
            phx-click="view_story"
            phx-value-user-id={user_id}
            class="flex flex-col items-center gap-1.5 shrink-0"
          >
            <div class="w-16 h-16 rounded-full p-[2px] bg-gradient-to-br from-sa-green to-sa-gold">
              <div class="w-full h-full rounded-full bg-sa-surface flex items-center justify-center overflow-hidden">
                <%= if user.avatar_url do %>
                  <img src={user.avatar_url} alt="" class="w-full h-full object-cover" />
                <% else %>
                  <span class="text-sa-green text-lg">
                    {String.first(user.display_name || user.username)}
                  </span>
                <% end %>
              </div>
            </div>
            <span class="text-xs text-sa-gray-light font-['DM_Sans'] max-w-[64px] truncate">
              {user.username}
            </span>
          </button>
        <% end %>
      </div>
    </div>
    """
  end
end
