defmodule SocialAppWeb.SuggestedUsersComponent do
  @moduledoc """
  Reusable LiveComponent showing suggested users to follow.
  """
  use SocialAppWeb, :live_component

  alias SocialApp.Social

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    users = Social.list_suggested_users(assigns.current_user_id, limit: assigns[:limit] || 5)

    {:ok,
     socket
     |> assign(:current_user_id, assigns.current_user_id)
     |> assign(:users, users)
     |> assign(:id, assigns.id)}
  end

  @impl true
  def handle_event("follow_user", %{"id" => id}, socket) do
    user_id = String.to_integer(id)
    Social.follow(socket.assigns.current_user_id, user_id)
    users = Social.list_suggested_users(socket.assigns.current_user_id, limit: 5)
    {:noreply, assign(socket, :users, users)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-sa-surface rounded-xl p-4">
      <h3 class="text-sm font-bold text-sa-gray-light font-['Sora'] uppercase tracking-wider mb-3">
        Who to Follow
      </h3>
      <%= if @users == [] do %>
        <p class="text-sa-gray text-sm font-['DM_Sans']">No suggestions right now</p>
      <% else %>
        <div class="space-y-3">
          <%= for user <- @users do %>
            <div class="flex items-center justify-between rtl:flex-row-reverse">
              <.link
                navigate={~p"/u/#{user.username}"}
                class="flex items-center gap-2.5 rtl:flex-row-reverse flex-1 min-w-0"
              >
                <div class="w-9 h-9 rounded-full bg-sa-surface2 overflow-hidden flex-shrink-0">
                  <%= if user.avatar_url do %>
                    <img
                      src={user.avatar_url}
                      alt={user.username}
                      class="w-full h-full object-cover"
                    />
                  <% else %>
                    <div class="w-full h-full flex items-center justify-center text-xs text-sa-green font-['Sora']">
                      {String.first(user.username) |> String.upcase()}
                    </div>
                  <% end %>
                </div>
                <div class="min-w-0">
                  <p class="text-sm font-medium text-sa-white truncate font-['Sora']">
                    {user.display_name || user.username}
                  </p>
                  <p class="text-xs text-sa-gray truncate">@{user.username}</p>
                </div>
              </.link>
              <button
                phx-click="follow_user"
                phx-value-id={user.id}
                phx-target={@myself}
                class="px-3 py-1 rounded-full bg-sa-green text-xs text-sa-white hover:bg-sa-green-light transition ms-2 flex-shrink-0"
              >
                Follow
              </button>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
