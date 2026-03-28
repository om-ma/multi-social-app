defmodule SocialAppWeb.Components.RightPanel do
  @moduledoc """
  Right panel component for desktop layout.
  Shows Stories section and Suggested Users.
  """
  use Phoenix.Component
  use SocialAppWeb, :verified_routes

  import SocialAppWeb.Components.StoriesRow

  attr :current_user, :map, required: true
  attr :stories_by_user, :map, default: %{}

  def right_panel(assigns) do
    ~H"""
    <aside class="hidden lg:block w-[300px] h-screen fixed top-0 end-0 z-20 bg-sa-surface border-s border-sa-border overflow-y-auto">
      <div class="p-4 space-y-5">
        <%!-- Stories section --%>
        <div>
          <h3 class="text-sm font-bold text-sa-gray-light font-['Sora'] uppercase tracking-wider mb-3">
            Stories
          </h3>
          <.stories_row stories_by_user={@stories_by_user} current_user={@current_user} />
        </div>

        <%!-- Suggested users --%>
        <div>
          <.live_component
            module={SocialAppWeb.SuggestedUsersComponent}
            id="sidebar-suggested-users"
            current_user_id={@current_user.id}
            limit={5}
          />
        </div>

        <%!-- Footer links --%>
        <div class="pt-3 border-t border-sa-border">
          <p class="text-xs text-sa-gray font-['DM_Sans']">
            &copy; 2026 SocialApp. All rights reserved.
          </p>
        </div>
      </div>
    </aside>
    """
  end
end
