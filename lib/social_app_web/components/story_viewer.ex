defmodule SocialAppWeb.Components.StoryViewer do
  use SocialAppWeb, :live_component

  @auto_advance_ms 5_000

  def mount(socket) do
    {:ok, assign(socket, current_index: 0)}
  end

  def update(assigns, socket) do
    stories = assigns.stories
    current_index = socket.assigns[:current_index] || 0

    socket =
      socket
      |> assign(assigns)
      |> assign(:current_index, current_index)
      |> assign(:total, length(stories))
      |> schedule_advance()

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div
      class="fixed inset-0 z-50 bg-black/95 flex items-center justify-center"
      phx-window-keydown="story_keydown"
      phx-target={@myself}
    >
      <div class="relative w-full max-w-md h-[90vh] bg-sa-surface rounded-2xl overflow-hidden">
        <%!-- Progress bars --%>
        <div class="absolute top-0 left-0 right-0 z-10 flex gap-1 p-2">
          <%= for i <- 0..(@total - 1) do %>
            <div class="flex-1 h-0.5 bg-sa-border rounded-full overflow-hidden">
              <div class={[
                "h-full bg-sa-white rounded-full transition-all duration-300",
                cond do
                  i < @current_index -> "w-full"
                  i == @current_index -> "w-1/2 animate-pulse"
                  true -> "w-0"
                end
              ]}>
              </div>
            </div>
          <% end %>
        </div>

        <%!-- Close button --%>
        <button
          phx-click="close_story"
          class="absolute top-4 right-4 rtl:right-auto rtl:left-4 z-10 text-sa-white/80 hover:text-sa-white"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="w-6 h-6"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="2"
          >
            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>

        <%!-- User info --%>
        <% story = Enum.at(@stories, @current_index) %>
        <div class="absolute top-8 left-4 rtl:left-auto rtl:right-4 z-10 flex items-center gap-2 rtl:flex-row-reverse">
          <div class="w-8 h-8 rounded-full bg-sa-surface2 flex items-center justify-center overflow-hidden">
            <%= if story.user.avatar_url do %>
              <img src={story.user.avatar_url} alt="" class="w-full h-full object-cover" />
            <% else %>
              <span class="text-sa-green text-sm">
                {String.first(story.user.display_name || story.user.username)}
              </span>
            <% end %>
          </div>
          <span class="text-sa-white text-sm font-['Sora'] font-semibold">
            {story.user.username}
          </span>
        </div>

        <%!-- Story content --%>
        <div class="w-full h-full flex items-center justify-center bg-sa-surface2">
          <%= if story.media_url do %>
            <div class="text-center text-sa-gray">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="w-12 h-12 mx-auto mb-2"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                stroke-width="1.5"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M2.25 15.75l5.159-5.159a2.25 2.25 0 013.182 0l5.159 5.159m-1.5-1.5l1.409-1.409a2.25 2.25 0 013.182 0l2.909 2.909M3.75 21h16.5A2.25 2.25 0 0024 18.75V5.25A2.25 2.25 0 0021.75 3H3.75A2.25 2.25 0 001.5 5.25v13.5A2.25 2.25 0 003.75 21z"
                />
              </svg>
              <p class="text-sm">Story Media</p>
            </div>
          <% else %>
            <p class="text-sa-gray text-sm">No media</p>
          <% end %>
        </div>

        <%!-- Navigation areas --%>
        <div class="absolute inset-0 flex">
          <button
            phx-click="story_prev"
            phx-target={@myself}
            class="w-1/3 h-full cursor-pointer"
          >
          </button>
          <div class="w-1/3"></div>
          <button
            phx-click="story_next"
            phx-target={@myself}
            class="w-1/3 h-full cursor-pointer"
          >
          </button>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("story_next", _params, socket) do
    next_index = socket.assigns.current_index + 1

    if next_index >= socket.assigns.total do
      send(self(), :close_story)
      {:noreply, socket}
    else
      {:noreply, socket |> assign(:current_index, next_index) |> schedule_advance()}
    end
  end

  def handle_event("story_prev", _params, socket) do
    prev_index = max(socket.assigns.current_index - 1, 0)
    {:noreply, socket |> assign(:current_index, prev_index) |> schedule_advance()}
  end

  def handle_event("story_keydown", %{"key" => "Escape"}, socket) do
    send(self(), :close_story)
    {:noreply, socket}
  end

  def handle_event("story_keydown", %{"key" => "ArrowRight"}, socket) do
    handle_event("story_next", %{}, socket)
  end

  def handle_event("story_keydown", %{"key" => "ArrowLeft"}, socket) do
    handle_event("story_prev", %{}, socket)
  end

  def handle_event("story_keydown", _params, socket) do
    {:noreply, socket}
  end

  defp schedule_advance(socket) do
    if connected?(socket) do
      if socket.assigns[:advance_timer], do: Process.cancel_timer(socket.assigns[:advance_timer])
      timer = Process.send_after(self(), {:story_advance, socket.assigns.id}, @auto_advance_ms)
      assign(socket, :advance_timer, timer)
    else
      socket
    end
  end
end
