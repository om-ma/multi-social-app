defmodule SocialAppWeb.Components.BottomNav do
  @moduledoc """
  Mobile bottom navigation bar with 5 items: Home, Reels, Create, Messages, Profile.
  """
  use Phoenix.Component
  use SocialAppWeb, :verified_routes

  attr :current_user, :map, required: true
  attr :current_path, :string, default: "/"
  attr :unread_messages, :integer, default: 0

  def bottom_nav(assigns) do
    ~H"""
    <nav class="flex md:hidden fixed bottom-0 inset-x-0 z-30 bg-sa-surface border-t border-sa-border safe-area-bottom">
      <div class="flex items-center justify-around w-full px-2 py-2 rtl:flex-row-reverse">
        <%!-- Home --%>
        <a
          href={~p"/feed"}
          class={[
            "flex flex-col items-center gap-0.5 px-3 py-1 rounded-lg transition-colors",
            if(@current_path == "/feed", do: "text-sa-green", else: "text-sa-gray-light")
          ]}
        >
          <span class="hero-home-solid w-6 h-6" />
          <span class="text-[10px] font-['DM_Sans']">Home</span>
        </a>

        <%!-- Reels --%>
        <a
          href={~p"/reels"}
          class={[
            "flex flex-col items-center gap-0.5 px-3 py-1 rounded-lg transition-colors",
            if(@current_path == "/reels", do: "text-sa-green", else: "text-sa-gray-light")
          ]}
        >
          <span class="hero-film-solid w-6 h-6" />
          <span class="text-[10px] font-['DM_Sans']">Reels</span>
        </a>

        <%!-- Create (gold circle) --%>
        <button
          phx-click="open_create_post"
          class="flex items-center justify-center w-12 h-12 rounded-full bg-sa-gold hover:bg-sa-gold-light transition-colors -mt-4 shadow-lg"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="w-6 h-6 text-sa-black"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="2.5"
          >
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
          </svg>
        </button>

        <%!-- Messages --%>
        <a
          href={~p"/messages"}
          class={[
            "flex flex-col items-center gap-0.5 px-3 py-1 rounded-lg transition-colors relative",
            if(@current_path == "/messages" || String.starts_with?(@current_path, "/messages/"),
              do: "text-sa-green",
              else: "text-sa-gray-light"
            )
          ]}
        >
          <span class="hero-chat-bubble-left-right-solid w-6 h-6" />
          <span
            :if={@unread_messages > 0}
            class="absolute -top-0.5 end-1 min-w-[16px] h-4 flex items-center justify-center rounded-full bg-sa-red text-white text-[10px] font-bold px-1"
          >
            {if @unread_messages > 99, do: "99+", else: @unread_messages}
          </span>
          <span class="text-[10px] font-['DM_Sans']">Messages</span>
        </a>

        <%!-- Profile --%>
        <a
          href={~p"/u/#{@current_user.username}"}
          class={[
            "flex flex-col items-center gap-0.5 px-3 py-1 rounded-lg transition-colors",
            if(@current_path == "/u/#{@current_user.username}",
              do: "text-sa-green",
              else: "text-sa-gray-light"
            )
          ]}
        >
          <span class="hero-user-solid w-6 h-6" />
          <span class="text-[10px] font-['DM_Sans']">Profile</span>
        </a>
      </div>
    </nav>
    """
  end
end
