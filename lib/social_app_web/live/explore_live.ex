defmodule SocialAppWeb.ExploreLive do
  use SocialAppWeb, :live_view

  alias SocialApp.Social

  @impl true
  def mount(_params, _session, socket) do
    suggested = Social.list_suggested_users(socket.assigns.current_user.id, limit: 12)

    {:ok,
     socket
     |> assign(:page_title, "Explore")
     |> assign(:query, "")
     |> assign(:results, [])
     |> assign(:searched, false)
     |> assign(:suggested, suggested)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    query = String.trim(query)

    if query == "" do
      {:noreply, assign(socket, query: "", results: [], searched: false)}
    else
      results = Social.search_users(query)
      {:noreply, assign(socket, query: query, results: results, searched: true)}
    end
  end

  def handle_event("follow_user", %{"id" => id}, socket) do
    user_id = String.to_integer(id)
    Social.follow(socket.assigns.current_user.id, user_id)
    suggested = Social.list_suggested_users(socket.assigns.current_user.id, limit: 12)

    results =
      if socket.assigns.searched,
        do: Social.search_users(socket.assigns.query),
        else: []

    {:noreply, assign(socket, suggested: suggested, results: results)}
  end

  def handle_event("unfollow_user", %{"id" => id}, socket) do
    user_id = String.to_integer(id)
    Social.unfollow(socket.assigns.current_user.id, user_id)
    suggested = Social.list_suggested_users(socket.assigns.current_user.id, limit: 12)

    results =
      if socket.assigns.searched,
        do: Social.search_users(socket.assigns.query),
        else: []

    {:noreply, assign(socket, suggested: suggested, results: results)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-sa-black">
      <div class="max-w-2xl mx-auto px-4 py-6">
        <h1 class="text-2xl font-bold font-['Sora'] text-sa-white mb-6">Explore</h1>

        <%!-- Search bar --%>
        <form phx-submit="search" phx-change="search" class="mb-6">
          <div class="relative">
            <span class="hero-magnifying-glass w-5 h-5 absolute top-3 start-3 text-sa-gray"></span>
            <input
              type="text"
              name="query"
              value={@query}
              placeholder="Search users..."
              autocomplete="off"
              class="w-full bg-sa-surface border border-sa-border rounded-xl ps-10 pe-4 py-2.5 text-sa-white font-['DM_Sans'] placeholder-sa-gray focus:border-sa-green focus:outline-none focus:ring-1 focus:ring-sa-green"
            />
          </div>
        </form>

        <%!-- Search results --%>
        <%= if @searched do %>
          <div class="mb-8">
            <h2 class="text-sm font-bold text-sa-gray-light font-['Sora'] uppercase tracking-wider mb-3">
              Search Results
            </h2>
            <%= if @results == [] do %>
              <p class="text-sa-gray font-['DM_Sans'] text-center py-8">No users found</p>
            <% else %>
              <div class="space-y-1">
                <%= for user <- @results do %>
                  <.user_card user={user} current_user_id={@current_user.id} />
                <% end %>
              </div>
            <% end %>
          </div>
        <% end %>

        <%!-- Suggested users --%>
        <div>
          <h2 class="text-sm font-bold text-sa-gray-light font-['Sora'] uppercase tracking-wider mb-3">
            Suggested for You
          </h2>
          <%= if @suggested == [] do %>
            <p class="text-sa-gray font-['DM_Sans'] text-center py-8">No suggestions available</p>
          <% else %>
            <div class="space-y-1">
              <%= for user <- @suggested do %>
                <.user_card user={user} current_user_id={@current_user.id} />
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp user_card(assigns) do
    ~H"""
    <div class="flex items-center justify-between p-3 rounded-lg hover:bg-sa-surface2 rtl:flex-row-reverse">
      <.link
        navigate={~p"/u/#{@user.username}"}
        class="flex items-center gap-3 rtl:flex-row-reverse flex-1 min-w-0"
      >
        <div class="w-10 h-10 rounded-full bg-sa-surface2 overflow-hidden flex-shrink-0">
          <%= if @user.avatar_url do %>
            <img src={@user.avatar_url} alt={@user.username} class="w-full h-full object-cover" />
          <% else %>
            <div class="w-full h-full flex items-center justify-center text-sm text-sa-green font-['Sora']">
              {String.first(@user.username) |> String.upcase()}
            </div>
          <% end %>
        </div>
        <div class="min-w-0">
          <p class="text-sm font-bold text-sa-white truncate font-['Sora']">
            {@user.display_name || @user.username}
          </p>
          <p class="text-xs text-sa-gray truncate">@{@user.username}</p>
        </div>
      </.link>
      <%= if @user.id != @current_user_id do %>
        <%= if SocialApp.Social.following?(@current_user_id, @user.id) do %>
          <button
            phx-click="unfollow_user"
            phx-value-id={@user.id}
            class="px-3 py-1 rounded-full border border-sa-border text-xs text-sa-white hover:border-sa-red hover:text-sa-red transition ms-2"
          >
            Following
          </button>
        <% else %>
          <button
            phx-click="follow_user"
            phx-value-id={@user.id}
            class="px-3 py-1 rounded-full bg-sa-green text-xs text-sa-white hover:bg-sa-green-light transition ms-2"
          >
            Follow
          </button>
        <% end %>
      <% end %>
    </div>
    """
  end
end
