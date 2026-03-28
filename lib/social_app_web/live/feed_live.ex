defmodule SocialAppWeb.FeedLive do
  use SocialAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-[#080C0A] flex items-center justify-center">
      <div class="text-center">
        <h1 class="text-2xl font-bold text-[#F0F7F2]">
          Welcome, {@current_user.display_name || @current_user.username}
        </h1>
        <p class="text-[#9AB0A0] mt-2">Feed coming soon</p>
        <a
          href={~p"/logout"}
          class="inline-block mt-4 px-4 py-2 bg-[#E05050] text-white rounded-xl text-sm"
        >
          Logout
        </a>
      </div>
    </div>
    """
  end
end
