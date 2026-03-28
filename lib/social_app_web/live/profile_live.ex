defmodule SocialAppWeb.ProfileLive do
  use SocialAppWeb, :live_view

  import Ecto.Query

  alias SocialApp.Accounts
  alias SocialApp.Social
  alias SocialApp.Content.Post

  @impl true
  def mount(%{"username" => username}, _session, socket) do
    case Accounts.get_user_by_username(username) do
      nil ->
        {:ok, socket |> put_flash(:error, "User not found") |> redirect(to: ~p"/feed")}

      profile_user ->
        current_user = socket.assigns.current_user
        is_own = current_user.id == profile_user.id

        following =
          if is_own, do: false, else: Social.following?(current_user.id, profile_user.id)

        posts =
          SocialApp.Repo.all(
            from(p in Post,
              where: p.user_id == ^profile_user.id,
              order_by: [desc: p.inserted_at],
              limit: 12
            )
          )

        {:ok,
         socket
         |> assign(:page_title, "@#{profile_user.username}")
         |> assign(:profile_user, profile_user)
         |> assign(:is_own, is_own)
         |> assign(:following, following)
         |> assign(:posts, posts)
         |> assign(:show_followers, false)
         |> assign(:show_following, false)
         |> assign(:modal_users, [])}
    end
  end

  @impl true
  def handle_event("follow", _, socket) do
    current_user = socket.assigns.current_user
    profile_user = socket.assigns.profile_user

    case Social.follow(current_user.id, profile_user.id) do
      {:ok, _} ->
        profile_user = Accounts.get_user!(profile_user.id)
        current_user = Accounts.get_user!(current_user.id)

        {:noreply,
         socket
         |> assign(:following, true)
         |> assign(:profile_user, profile_user)
         |> assign(:current_user, current_user)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("unfollow", _, socket) do
    current_user = socket.assigns.current_user
    profile_user = socket.assigns.profile_user

    case Social.unfollow(current_user.id, profile_user.id) do
      :ok ->
        profile_user = Accounts.get_user!(profile_user.id)
        current_user = Accounts.get_user!(current_user.id)

        {:noreply,
         socket
         |> assign(:following, false)
         |> assign(:profile_user, profile_user)
         |> assign(:current_user, current_user)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("show_followers", _, socket) do
    users = Social.list_followers(socket.assigns.profile_user.id)

    {:noreply,
     socket
     |> assign(:show_followers, true)
     |> assign(:show_following, false)
     |> assign(:modal_users, users)}
  end

  def handle_event("show_following", _, socket) do
    users = Social.list_following(socket.assigns.profile_user.id)

    {:noreply,
     socket
     |> assign(:show_following, true)
     |> assign(:show_followers, false)
     |> assign(:modal_users, users)}
  end

  def handle_event("close_modal", _, socket) do
    {:noreply,
     socket
     |> assign(:show_followers, false)
     |> assign(:show_following, false)
     |> assign(:modal_users, [])}
  end

  def handle_event("follow_user", %{"id" => id}, socket) do
    user_id = String.to_integer(id)
    Social.follow(socket.assigns.current_user.id, user_id)
    # Refresh the modal list
    modal_users = refresh_modal_users(socket)
    {:noreply, assign(socket, :modal_users, modal_users)}
  end

  def handle_event("unfollow_user", %{"id" => id}, socket) do
    user_id = String.to_integer(id)
    Social.unfollow(socket.assigns.current_user.id, user_id)
    modal_users = refresh_modal_users(socket)
    {:noreply, assign(socket, :modal_users, modal_users)}
  end

  defp refresh_modal_users(socket) do
    profile_user = socket.assigns.profile_user

    if socket.assigns.show_followers do
      Social.list_followers(profile_user.id)
    else
      Social.list_following(profile_user.id)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-sa-black">
      <%!-- Cover --%>
      <div class="relative h-48 md:h-64 bg-sa-surface">
        <%= if @profile_user.cover_url do %>
          <img src={@profile_user.cover_url} alt="Cover" class="w-full h-full object-cover" />
        <% else %>
          <div class="w-full h-full bg-gradient-to-br from-sa-green/30 to-sa-surface"></div>
        <% end %>
      </div>

      <%!-- Profile header --%>
      <div class="max-w-2xl mx-auto px-4 rtl:pr-4 rtl:pl-4">
        <div class="relative -mt-16 flex items-end justify-between">
          <%!-- Avatar --%>
          <div class="w-28 h-28 rounded-full border-4 border-sa-black overflow-hidden bg-sa-surface2 flex-shrink-0">
            <%= if @profile_user.avatar_url do %>
              <img
                src={@profile_user.avatar_url}
                alt={@profile_user.username}
                class="w-full h-full object-cover"
              />
            <% else %>
              <div class="w-full h-full flex items-center justify-center text-3xl font-['Sora'] text-sa-green">
                {String.first(@profile_user.username) |> String.upcase()}
              </div>
            <% end %>
          </div>

          <%!-- Action button --%>
          <div class="pb-2">
            <%= if @is_own do %>
              <.link
                navigate={~p"/settings/profile"}
                class="px-5 py-2 rounded-full border border-sa-border text-sa-white text-sm font-['DM_Sans'] hover:bg-sa-surface2 transition"
              >
                Edit Profile
              </.link>
            <% else %>
              <%= if @following do %>
                <button
                  phx-click="unfollow"
                  class="px-5 py-2 rounded-full border border-sa-border text-sa-white text-sm font-['DM_Sans'] hover:border-sa-red hover:text-sa-red transition"
                >
                  Following
                </button>
              <% else %>
                <button
                  phx-click="follow"
                  class="px-5 py-2 rounded-full bg-sa-green text-sa-white text-sm font-['DM_Sans'] hover:bg-sa-green-light transition"
                >
                  Follow
                </button>
              <% end %>
            <% end %>
          </div>
        </div>

        <%!-- Name & bio --%>
        <div class="mt-3">
          <h1 class="text-xl font-bold font-['Sora'] text-sa-white">
            {@profile_user.display_name || @profile_user.username}
          </h1>
          <p class="text-sa-gray text-sm">@{@profile_user.username}</p>

          <%= if @profile_user.bio do %>
            <p class="mt-2 text-sa-white text-sm leading-relaxed font-['DM_Sans']">
              {@profile_user.bio}
            </p>
          <% end %>

          <%= if @profile_user.location do %>
            <p class="mt-1 text-sa-gray text-xs flex items-center gap-1 rtl:flex-row-reverse">
              <span class="hero-map-pin-mini w-4 h-4"></span>
              {@profile_user.location}
            </p>
          <% end %>
        </div>

        <%!-- Stats --%>
        <div class="mt-4 flex gap-6 rtl:flex-row-reverse text-sm font-['DM_Sans']">
          <button phx-click="show_following" class="hover:underline">
            <span class="font-bold text-sa-white">{@profile_user.following_count}</span>
            <span class="text-sa-gray ms-1">Following</span>
          </button>
          <button phx-click="show_followers" class="hover:underline">
            <span class="font-bold text-sa-white">{@profile_user.followers_count}</span>
            <span class="text-sa-gray ms-1">Followers</span>
          </button>
          <div>
            <span class="font-bold text-sa-white">{@profile_user.posts_count}</span>
            <span class="text-sa-gray ms-1">Posts</span>
          </div>
        </div>

        <%!-- Divider --%>
        <div class="border-t border-sa-border mt-4"></div>

        <%!-- Posts grid --%>
        <div class="mt-4 pb-8">
          <%= if @posts == [] do %>
            <p class="text-center text-sa-gray py-12 font-['DM_Sans']">No posts yet</p>
          <% else %>
            <div class="grid grid-cols-3 gap-1">
              <%= for post <- @posts do %>
                <div class="aspect-square bg-sa-surface rounded overflow-hidden">
                  <%= if post.media_url do %>
                    <img
                      src={post.media_url}
                      alt=""
                      class="w-full h-full object-cover hover:opacity-80 transition"
                    />
                  <% else %>
                    <div class="w-full h-full p-2 flex items-center justify-center text-xs text-sa-gray-light font-['DM_Sans'] text-center">
                      {String.slice(post.content || "", 0..60)}
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>

      <%!-- Followers / Following Modal --%>
      <%= if @show_followers or @show_following do %>
        <div
          class="fixed inset-0 z-50 flex items-center justify-center bg-black/60"
          phx-click="close_modal"
        >
          <div
            class="bg-sa-surface rounded-xl w-full max-w-md max-h-[70vh] overflow-y-auto mx-4"
            phx-click-away="close_modal"
          >
            <div class="sticky top-0 bg-sa-surface border-b border-sa-border p-4 flex items-center justify-between rtl:flex-row-reverse">
              <h2 class="text-lg font-bold font-['Sora'] text-sa-white">
                {if @show_followers, do: "Followers", else: "Following"}
              </h2>
              <button phx-click="close_modal" class="text-sa-gray hover:text-sa-white">
                <span class="hero-x-mark w-5 h-5"></span>
              </button>
            </div>
            <div class="p-2">
              <%= if @modal_users == [] do %>
                <p class="text-center text-sa-gray py-8 font-['DM_Sans']">No users yet</p>
              <% else %>
                <%= for user <- @modal_users do %>
                  <div class="flex items-center justify-between p-3 rounded-lg hover:bg-sa-surface2 rtl:flex-row-reverse">
                    <.link
                      navigate={~p"/u/#{user.username}"}
                      class="flex items-center gap-3 rtl:flex-row-reverse flex-1 min-w-0"
                    >
                      <div class="w-10 h-10 rounded-full bg-sa-surface2 overflow-hidden flex-shrink-0">
                        <%= if user.avatar_url do %>
                          <img
                            src={user.avatar_url}
                            alt={user.username}
                            class="w-full h-full object-cover"
                          />
                        <% else %>
                          <div class="w-full h-full flex items-center justify-center text-sm text-sa-green font-['Sora']">
                            {String.first(user.username) |> String.upcase()}
                          </div>
                        <% end %>
                      </div>
                      <div class="min-w-0">
                        <p class="text-sm font-bold text-sa-white truncate font-['Sora']">
                          {user.display_name || user.username}
                        </p>
                        <p class="text-xs text-sa-gray truncate">@{user.username}</p>
                      </div>
                    </.link>
                    <%= if user.id != @current_user.id do %>
                      <%= if Social.following?(@current_user.id, user.id) do %>
                        <button
                          phx-click="unfollow_user"
                          phx-value-id={user.id}
                          class="px-3 py-1 rounded-full border border-sa-border text-xs text-sa-white hover:border-sa-red hover:text-sa-red transition ms-2"
                        >
                          Following
                        </button>
                      <% else %>
                        <button
                          phx-click="follow_user"
                          phx-value-id={user.id}
                          class="px-3 py-1 rounded-full bg-sa-green text-xs text-sa-white hover:bg-sa-green-light transition ms-2"
                        >
                          Follow
                        </button>
                      <% end %>
                    <% end %>
                  </div>
                <% end %>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
