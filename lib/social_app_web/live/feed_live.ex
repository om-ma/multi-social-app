defmodule SocialAppWeb.FeedLive do
  use SocialAppWeb, :live_view

  import SocialAppWeb.Components.PostCard
  import SocialAppWeb.Components.StoriesRow

  alias SocialApp.Feed

  @page_size 10

  def mount(_params, _session, socket) do
    posts = Feed.list_feed_posts(limit: @page_size, offset: 0)
    stories_by_user = Feed.list_active_stories()

    post_ids = Enum.map(posts, & &1.id)
    liked_ids = Feed.list_user_liked_post_ids(socket.assigns.current_user.id, post_ids)

    socket =
      socket
      |> assign(:posts, posts)
      |> assign(:liked_ids, liked_ids)
      |> assign(:stories_by_user, stories_by_user)
      |> assign(:page, 0)
      |> assign(:has_more, length(posts) == @page_size)
      |> assign(:show_create_post, false)
      |> assign(:viewing_stories, nil)
      |> assign(:page_title, "Feed")

    {:ok, socket}
  end

  def handle_event("load_more", _params, socket) do
    next_page = socket.assigns.page + 1
    offset = next_page * @page_size
    new_posts = Feed.list_feed_posts(limit: @page_size, offset: offset)

    new_post_ids = Enum.map(new_posts, & &1.id)

    new_liked =
      Feed.list_user_liked_post_ids(socket.assigns.current_user.id, new_post_ids)

    liked_ids = MapSet.union(socket.assigns.liked_ids, new_liked)

    socket =
      socket
      |> assign(:posts, socket.assigns.posts ++ new_posts)
      |> assign(:liked_ids, liked_ids)
      |> assign(:page, next_page)
      |> assign(:has_more, length(new_posts) == @page_size)

    {:noreply, socket}
  end

  def handle_event("toggle_like", %{"post-id" => post_id_str}, socket) do
    post_id = String.to_integer(post_id_str)
    user_id = socket.assigns.current_user.id
    currently_liked = MapSet.member?(socket.assigns.liked_ids, post_id)

    # Optimistic update
    {liked_ids, posts} =
      if currently_liked do
        {MapSet.delete(socket.assigns.liked_ids, post_id),
         update_post_likes_count(socket.assigns.posts, post_id, -1)}
      else
        {MapSet.put(socket.assigns.liked_ids, post_id),
         update_post_likes_count(socket.assigns.posts, post_id, 1)}
      end

    socket = socket |> assign(:liked_ids, liked_ids) |> assign(:posts, posts)

    # Perform actual operation
    if currently_liked do
      Feed.unlike_post(user_id, post_id)
    else
      Feed.like_post(user_id, post_id)
    end

    {:noreply, socket}
  end

  def handle_event("open_create_post", _params, socket) do
    {:noreply, assign(socket, :show_create_post, true)}
  end

  def handle_event("close_create_post", _params, socket) do
    {:noreply, assign(socket, :show_create_post, false)}
  end

  def handle_event("create_post", %{"content" => content} = params, socket) do
    attrs =
      %{"content" => content}
      |> maybe_put_media(params)

    case Feed.create_post(socket.assigns.current_user.id, attrs) do
      {:ok, post} ->
        socket =
          socket
          |> assign(:posts, [post | socket.assigns.posts])
          |> assign(:show_create_post, false)

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not create post.")}
    end
  end

  def handle_event("view_story", %{"user-id" => user_id_str}, socket) do
    user_id = String.to_integer(user_id_str)
    stories = Map.get(socket.assigns.stories_by_user, user_id, [])

    if stories != [] do
      {:noreply, assign(socket, :viewing_stories, stories)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("close_story", _params, socket) do
    {:noreply, assign(socket, :viewing_stories, nil)}
  end

  def handle_event("open_create_story", _params, socket) do
    # Placeholder - stories need media_url
    {:noreply, socket}
  end

  def handle_info(:close_story, socket) do
    {:noreply, assign(socket, :viewing_stories, nil)}
  end

  def handle_info({:story_advance, _id}, socket) do
    # Story auto-advance is handled inside the component
    {:noreply, socket}
  end

  defp update_post_likes_count(posts, post_id, delta) do
    Enum.map(posts, fn post ->
      if post.id == post_id do
        %{post | likes_count: max(post.likes_count + delta, 0)}
      else
        post
      end
    end)
  end

  defp maybe_put_media(attrs, %{"media_type" => media_type})
       when media_type in ["image", "video"] do
    Map.merge(attrs, %{"media_type" => media_type, "media_url" => "placeholder://#{media_type}"})
  end

  defp maybe_put_media(attrs, _params), do: attrs

  def render(assigns) do
    ~H"""
    <div class="px-4 py-6">
      <%!-- Header --%>
      <div class="flex items-center justify-between mb-6 rtl:flex-row-reverse">
        <h1 class="font-['Sora'] text-2xl font-bold text-sa-white">Feed</h1>
      </div>

      <%!-- Stories row (mobile only, desktop shows in right panel) --%>
      <div class="lg:hidden">
        <.stories_row stories_by_user={@stories_by_user} current_user={@current_user} />
      </div>

      <%!-- Posts --%>
      <div id="feed-posts">
        <%= for post <- @posts do %>
          <.post_card post={post} liked={MapSet.member?(@liked_ids, post.id)} />
        <% end %>
      </div>

      <%!-- Load more --%>
      <%= if @has_more do %>
        <div class="flex justify-center py-6">
          <button
            phx-click="load_more"
            class="bg-sa-surface hover:bg-sa-surface2 text-sa-gray-light font-['DM_Sans'] text-sm px-6 py-2.5 rounded-xl border border-sa-border transition-colors"
          >
            Load more
          </button>
        </div>
      <% end %>

      <%= if @posts == [] do %>
        <div class="text-center py-12">
          <p class="text-sa-gray text-sm">No posts yet. Be the first to share something!</p>
        </div>
      <% end %>

      <%!-- Story viewer --%>
      <%= if @viewing_stories do %>
        <.live_component
          module={SocialAppWeb.Components.StoryViewer}
          id="story-viewer"
          stories={@viewing_stories}
        />
      <% end %>
    </div>
    """
  end
end
