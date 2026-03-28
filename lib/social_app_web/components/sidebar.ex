defmodule SocialAppWeb.Components.Sidebar do
  @moduledoc """
  Left sidebar navigation component for desktop.
  Includes logo, nav items with badges, search, create post button, and user footer.
  """
  use Phoenix.Component
  use SocialAppWeb, :verified_routes

  attr :current_user, :map, required: true
  attr :current_path, :string, default: "/"
  attr :unread_notifications, :integer, default: 0
  attr :unread_messages, :integer, default: 0
  attr :search_results, :list, default: []
  attr :search_query, :string, default: ""

  def sidebar(assigns) do
    ~H"""
    <aside class="hidden md:flex flex-col w-[260px] h-screen bg-sa-surface border-e border-sa-border fixed top-0 start-0 z-30">
      <%!-- Logo --%>
      <div class="px-5 py-6">
        <a href={~p"/feed"} class="flex items-center gap-0.5">
          <span class="font-['Sora'] text-xl font-bold text-sa-green">Social</span>
          <span class="font-['Sora'] text-xl font-bold text-sa-gold">App</span>
        </a>
      </div>

      <%!-- Search --%>
      <div class="px-4 mb-3">
        <div class="relative">
          <span class="hero-magnifying-glass-mini w-4 h-4 absolute top-2.5 start-3 text-sa-gray">
          </span>
          <input
            type="text"
            name="search"
            value={@search_query}
            placeholder="Search..."
            autocomplete="off"
            phx-keyup="sidebar_search"
            phx-debounce="300"
            class="w-full bg-sa-surface2 border border-sa-border rounded-lg ps-9 pe-3 py-2 text-sm text-sa-white font-['DM_Sans'] placeholder-sa-gray focus:border-sa-green focus:outline-none focus:ring-1 focus:ring-sa-green"
          />
          <%!-- Search dropdown --%>
          <div
            :if={@search_query != "" && @search_results != []}
            class="absolute top-full mt-1 start-0 end-0 bg-sa-surface2 border border-sa-border rounded-lg shadow-lg z-50 max-h-64 overflow-y-auto"
          >
            <a
              :for={user <- @search_results}
              href={~p"/u/#{user.username}"}
              class="flex items-center gap-2.5 px-3 py-2 hover:bg-sa-surface3 transition-colors rtl:flex-row-reverse"
            >
              <div class="w-8 h-8 rounded-full bg-sa-surface3 overflow-hidden flex-shrink-0 flex items-center justify-center">
                <img
                  :if={user.avatar_url}
                  src={user.avatar_url}
                  alt={user.username}
                  class="w-full h-full object-cover"
                />
                <span
                  :if={!user.avatar_url}
                  class="text-xs text-sa-green font-['Sora']"
                >
                  {String.first(user.username) |> String.upcase()}
                </span>
              </div>
              <div class="min-w-0">
                <p class="text-sm text-sa-white truncate font-['DM_Sans']">
                  {user.display_name || user.username}
                </p>
                <p class="text-xs text-sa-gray truncate">@{user.username}</p>
              </div>
            </a>
          </div>
          <div
            :if={@search_query != "" && @search_results == []}
            class="absolute top-full mt-1 start-0 end-0 bg-sa-surface2 border border-sa-border rounded-lg shadow-lg z-50 p-3"
          >
            <p class="text-sm text-sa-gray text-center font-['DM_Sans']">No results found</p>
          </div>
        </div>
      </div>

      <%!-- Nav items --%>
      <nav class="flex-1 px-3 space-y-1 overflow-y-auto">
        <.nav_item
          href={~p"/feed"}
          icon="hero-home-solid"
          label="Home"
          active={@current_path == "/feed"}
        />
        <.nav_item
          href={~p"/explore"}
          icon="hero-magnifying-glass-solid"
          label="Explore"
          active={@current_path == "/explore"}
        />
        <.nav_item
          href={~p"/reels"}
          icon="hero-film-solid"
          label="Reels"
          active={@current_path == "/reels"}
        />
        <.nav_item
          href={~p"/messages"}
          icon="hero-chat-bubble-left-right-solid"
          label="Messages"
          active={@current_path == "/messages" || String.starts_with?(@current_path, "/messages/")}
          badge={@unread_messages}
        />
        <.nav_item
          href={~p"/notifications"}
          icon="hero-bell-solid"
          label="Notifications"
          active={@current_path == "/notifications"}
          badge={@unread_notifications}
        />
        <.nav_item
          href={~p"/u/#{@current_user.username}"}
          icon="hero-user-solid"
          label="Profile"
          active={@current_path == "/u/#{@current_user.username}"}
        />

        <%!-- Create Post button --%>
        <div class="pt-4">
          <button
            phx-click="open_create_post"
            class="w-full bg-sa-gold hover:bg-sa-gold-light text-sa-black font-['Sora'] font-semibold text-sm py-2.5 rounded-xl transition-colors flex items-center justify-center gap-2"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="w-4 h-4"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="2.5"
            >
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
            </svg>
            Create Post
          </button>
        </div>
      </nav>

      <%!-- User footer --%>
      <div class="px-4 py-4 border-t border-sa-border">
        <a
          href={~p"/u/#{@current_user.username}"}
          class="flex items-center gap-3 rtl:flex-row-reverse"
        >
          <div class="w-9 h-9 rounded-full bg-sa-surface2 overflow-hidden flex-shrink-0 flex items-center justify-center">
            <img
              :if={@current_user.avatar_url}
              src={@current_user.avatar_url}
              alt={@current_user.username}
              class="w-full h-full object-cover"
            />
            <span
              :if={!@current_user.avatar_url}
              class="text-sm text-sa-green font-['Sora']"
            >
              {String.first(@current_user.username) |> String.upcase()}
            </span>
          </div>
          <div class="min-w-0 flex-1">
            <p class="text-sm font-semibold text-sa-white truncate font-['Sora']">
              {@current_user.display_name || @current_user.username}
            </p>
            <p class="text-xs text-sa-gray truncate">@{@current_user.username}</p>
          </div>
        </a>
      </div>
    </aside>
    """
  end

  attr :href, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :active, :boolean, default: false
  attr :badge, :integer, default: 0

  defp nav_item(assigns) do
    ~H"""
    <a
      href={@href}
      data-phx-link="redirect"
      data-phx-link-state="push"
      class={[
        "flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-['DM_Sans'] font-medium transition-colors rtl:flex-row-reverse",
        if(@active,
          do: "bg-sa-green/20 text-sa-green",
          else: "text-sa-gray-light hover:bg-sa-surface2 hover:text-sa-white"
        )
      ]}
    >
      <span class={[@icon, "w-5 h-5 flex-shrink-0"]} />
      <span class="flex-1">{@label}</span>
      <span
        :if={@badge > 0}
        class="min-w-[20px] h-5 flex items-center justify-center rounded-full bg-sa-red text-white text-xs font-bold px-1.5"
      >
        {if @badge > 99, do: "99+", else: @badge}
      </span>
    </a>
    """
  end
end
