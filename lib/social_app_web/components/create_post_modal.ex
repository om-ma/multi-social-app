defmodule SocialAppWeb.Components.CreatePostModal do
  use Phoenix.Component

  attr :show, :boolean, default: false

  def create_post_modal(assigns) do
    ~H"""
    <%= if @show do %>
      <div
        class="fixed inset-0 z-40 flex items-center justify-center bg-black/70"
        phx-click="close_create_post"
      >
        <div
          class="bg-sa-surface border border-sa-border rounded-2xl w-full max-w-lg mx-4 p-6"
          phx-click-away="close_create_post"
          phx-window-keydown="close_create_post"
          phx-key="Escape"
        >
          <div class="flex items-center justify-between mb-4 rtl:flex-row-reverse">
            <h2 class="font-['Sora'] text-lg font-semibold text-sa-white">Create Post</h2>
            <button phx-click="close_create_post" class="text-sa-gray hover:text-sa-white">
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

          <form phx-submit="create_post" class="space-y-4">
            <textarea
              name="content"
              rows="4"
              placeholder="What's on your mind?"
              class="w-full bg-sa-surface2 border border-sa-border rounded-xl p-3 text-sa-white font-['DM_Sans'] text-sm placeholder-sa-gray focus:outline-none focus:border-sa-green resize-none"
              required
            ></textarea>

            <div class="flex items-center gap-2 rtl:flex-row-reverse">
              <span class="text-sa-gray text-xs">Media type:</span>
              <label class="flex items-center gap-1 text-sm text-sa-gray-light cursor-pointer">
                <input type="radio" name="media_type" value="image" class="accent-sa-green" /> Image
              </label>
              <label class="flex items-center gap-1 text-sm text-sa-gray-light cursor-pointer">
                <input type="radio" name="media_type" value="video" class="accent-sa-green" /> Video
              </label>
              <label class="flex items-center gap-1 text-sm text-sa-gray-light cursor-pointer">
                <input type="radio" name="media_type" value="" checked class="accent-sa-green" /> None
              </label>
            </div>

            <div class="flex justify-end rtl:justify-start">
              <button
                type="submit"
                class="bg-sa-green hover:bg-sa-green-light text-sa-white font-['Sora'] font-semibold text-sm px-6 py-2.5 rounded-xl transition-colors"
              >
                Post
              </button>
            </div>
          </form>
        </div>
      </div>
    <% end %>
    """
  end
end
