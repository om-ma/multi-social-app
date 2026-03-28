defmodule SocialAppWeb.ReelsLive do
  use SocialAppWeb, :live_view

  import SocialAppWeb.Components.ReelItem

  alias SocialApp.Reels

  @impl true
  def mount(_params, _session, socket) do
    reels = Reels.list_reels(page: 1)
    liked_ids = build_liked_ids(socket.assigns.current_user.id, reels)

    {:ok,
     assign(socket,
       reels: reels,
       liked_ids: liked_ids,
       tab: "for_you",
       page: 1,
       show_upload_modal: false,
       caption: ""
     )}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => "following"}, socket) do
    reels = Reels.list_following_reels(socket.assigns.current_user.id, page: 1)
    liked_ids = build_liked_ids(socket.assigns.current_user.id, reels)

    {:noreply,
     assign(socket,
       reels: reels,
       liked_ids: liked_ids,
       tab: "following",
       page: 1
     )}
  end

  def handle_event("switch_tab", %{"tab" => "for_you"}, socket) do
    reels = Reels.list_reels(page: 1)
    liked_ids = build_liked_ids(socket.assigns.current_user.id, reels)

    {:noreply,
     assign(socket,
       reels: reels,
       liked_ids: liked_ids,
       tab: "for_you",
       page: 1
     )}
  end

  def handle_event("toggle_like", %{"reel-id" => reel_id}, socket) do
    reel_id = String.to_integer(reel_id)
    user_id = socket.assigns.current_user.id
    liked_ids = socket.assigns.liked_ids

    {liked_ids, reels} =
      if MapSet.member?(liked_ids, reel_id) do
        Reels.unlike_reel(user_id, reel_id)

        reels =
          Enum.map(socket.assigns.reels, fn r ->
            if r.id == reel_id, do: %{r | likes_count: max(r.likes_count - 1, 0)}, else: r
          end)

        {MapSet.delete(liked_ids, reel_id), reels}
      else
        Reels.like_reel(user_id, reel_id)

        reels =
          Enum.map(socket.assigns.reels, fn r ->
            if r.id == reel_id, do: %{r | likes_count: r.likes_count + 1}, else: r
          end)

        {MapSet.put(liked_ids, reel_id), reels}
      end

    {:noreply, assign(socket, liked_ids: liked_ids, reels: reels)}
  end

  def handle_event("open_upload_modal", _params, socket) do
    {:noreply, assign(socket, show_upload_modal: true)}
  end

  def handle_event("close_upload_modal", _params, socket) do
    {:noreply, assign(socket, show_upload_modal: false, caption: "")}
  end

  def handle_event("save_reel", %{"caption" => caption}, socket) do
    user = socket.assigns.current_user

    case Reels.create_reel(user, %{
           "video_url" =>
             "https://placeholder.test/video_#{System.unique_integer([:positive])}.mp4",
           "caption" => caption
         }) do
      {:ok, _reel} ->
        reels =
          if socket.assigns.tab == "for_you" do
            Reels.list_reels(page: 1)
          else
            Reels.list_following_reels(user.id, page: 1)
          end

        liked_ids = build_liked_ids(user.id, reels)

        {:noreply,
         assign(socket,
           reels: reels,
           liked_ids: liked_ids,
           show_upload_modal: false,
           caption: "",
           page: 1
         )}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-sa-black z-40 flex flex-col">
      <%!-- Top bar: Tabs + Upload --%>
      <div class="absolute top-0 inset-x-0 z-50 flex items-center justify-center pt-4 pb-2 px-4">
        <div class="flex items-center gap-6">
          <button
            phx-click="switch_tab"
            phx-value-tab="following"
            class={[
              "text-sm font-['Sora'] font-semibold pb-1 border-b-2 transition-colors",
              if(@tab == "following",
                do: "text-sa-white border-sa-green",
                else: "text-sa-gray border-transparent"
              )
            ]}
          >
            Following
          </button>
          <button
            phx-click="switch_tab"
            phx-value-tab="for_you"
            class={[
              "text-sm font-['Sora'] font-semibold pb-1 border-b-2 transition-colors",
              if(@tab == "for_you",
                do: "text-sa-white border-sa-green",
                else: "text-sa-gray border-transparent"
              )
            ]}
          >
            For You
          </button>
        </div>

        <button
          phx-click="open_upload_modal"
          class="absolute right-4 top-4 w-9 h-9 rounded-full bg-sa-green flex items-center justify-center"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="w-5 h-5 text-sa-white"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="2"
          >
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
          </svg>
        </button>
      </div>

      <%!-- Reels scroll container --%>
      <div
        class="reels-scroll-container flex-1 overflow-y-scroll snap-y snap-mandatory"
        id="reels-container"
      >
        <%= if @reels == [] do %>
          <div class="w-full h-screen flex items-center justify-center snap-start">
            <div class="text-center">
              <p class="text-sa-gray text-lg font-['DM_Sans']">No reels yet</p>
              <p class="text-sa-gray-light text-sm mt-2 font-['DM_Sans']">
                <%= if @tab == "following" do %>
                  Follow some users to see their reels
                <% else %>
                  Be the first to create a reel!
                <% end %>
              </p>
            </div>
          </div>
        <% else %>
          <%= for reel <- @reels do %>
            <.reel_item
              reel={reel}
              liked={MapSet.member?(@liked_ids, reel.id)}
              current_user={@current_user}
            />
          <% end %>
        <% end %>
      </div>

      <%!-- Upload Modal --%>
      <%= if @show_upload_modal do %>
        <div
          class="fixed inset-0 z-[60] bg-sa-black/80 backdrop-blur-sm flex items-center justify-center p-4"
          phx-click="close_upload_modal"
        >
          <div
            class="bg-sa-surface rounded-2xl w-full max-w-md p-6 border border-sa-border"
            phx-click-away="close_upload_modal"
          >
            <div class="flex items-center justify-between mb-6">
              <h2 class="text-sa-white text-lg font-bold font-['Sora']">Create Reel</h2>
              <button
                phx-click="close_upload_modal"
                class="text-sa-gray hover:text-sa-white transition-colors"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="w-5 h-5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  stroke-width="2"
                >
                  <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            <form phx-submit="save_reel">
              <%!-- File input placeholder --%>
              <div class="mb-4">
                <label class="block text-sa-gray-light text-sm font-['DM_Sans'] mb-2">Video</label>
                <div class="border-2 border-dashed border-sa-border rounded-xl p-8 text-center cursor-pointer hover:border-sa-green transition-colors">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="w-10 h-10 mx-auto text-sa-gray mb-2"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                    stroke-width="1.5"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5m-13.5-9L12 3m0 0l4.5 4.5M12 3v13.5"
                    />
                  </svg>
                  <p class="text-sa-gray text-sm font-['DM_Sans']">Tap to upload video</p>
                  <p class="text-sa-gray-light text-xs mt-1 font-['DM_Sans']">MP4, MOV up to 60s</p>
                </div>
              </div>

              <%!-- Caption --%>
              <div class="mb-6">
                <label class="block text-sa-gray-light text-sm font-['DM_Sans'] mb-2">Caption</label>
                <textarea
                  name="caption"
                  rows="3"
                  placeholder="Write a caption..."
                  class="w-full bg-sa-surface2 border border-sa-border rounded-xl px-4 py-3 text-sa-white text-sm font-['DM_Sans'] placeholder-sa-gray focus:outline-none focus:border-sa-green resize-none"
                ></textarea>
              </div>

              <button
                type="submit"
                class="w-full bg-sa-green hover:bg-sa-green-light text-sa-white font-['Sora'] font-semibold py-3 rounded-xl transition-colors"
              >
                Post Reel
              </button>
            </form>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp build_liked_ids(user_id, reels) do
    reels
    |> Enum.map(& &1.id)
    |> Enum.filter(&Reels.liked_by?(user_id, &1))
    |> MapSet.new()
  end
end
