defmodule SocialAppWeb.CallLive do
  use SocialAppWeb, :live_view

  alias SocialApp.Calls

  def mount(%{"id" => id}, _session, socket) do
    call = Calls.get_call!(id)
    current_user = socket.assigns.current_user

    unless call.caller_id == current_user.id or call.receiver_id == current_user.id do
      raise Ecto.NoResultsError, queryable: SocialApp.Calls.Call
    end

    is_caller = call.caller_id == current_user.id

    other_user =
      if is_caller do
        call.receiver
      else
        call.caller
      end

    turn_url = System.get_env("METERED_TURN_URL") || ""
    turn_api_key = System.get_env("METERED_API_KEY") || ""

    socket =
      socket
      |> assign(:call, call)
      |> assign(:is_caller, is_caller)
      |> assign(:other_user, other_user)
      |> assign(:call_status, call.status)
      |> assign(:muted, false)
      |> assign(:camera_off, false)
      |> assign(:call_duration, 0)
      |> assign(:turn_url, turn_url)
      |> assign(:turn_api_key, turn_api_key)
      |> assign(:page_title, "Call")

    if connected?(socket) and call.status == "active" do
      Process.send_after(self(), :tick_timer, 1000)
    end

    {:ok, socket}
  end

  def handle_info(:tick_timer, socket) do
    if socket.assigns.call_status == "active" do
      Process.send_after(self(), :tick_timer, 1000)
      {:noreply, assign(socket, :call_duration, socket.assigns.call_duration + 1)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("toggle_mute", _params, socket) do
    {:noreply, assign(socket, :muted, !socket.assigns.muted)}
  end

  def handle_event("toggle_camera", _params, socket) do
    {:noreply, assign(socket, :camera_off, !socket.assigns.camera_off)}
  end

  def handle_event("end_call", _params, socket) do
    {:noreply, push_event(socket, "end_call", %{})}
  end

  def handle_event("accept_call", _params, socket) do
    call = Calls.get_call!(socket.assigns.call.id)
    {:ok, call} = Calls.update_call_status(call, "active")
    Process.send_after(self(), :tick_timer, 1000)

    socket =
      socket
      |> assign(:call, call)
      |> assign(:call_status, "active")
      |> push_event("accept_call", %{})

    {:noreply, socket}
  end

  def handle_event("decline_call", _params, socket) do
    {:noreply, push_event(socket, "decline_call", %{})}
  end

  def handle_event("call_connected", _params, socket) do
    if socket.assigns.call_status != "active" do
      call = Calls.get_call!(socket.assigns.call.id)

      case Calls.update_call_status(call, "active") do
        {:ok, call} ->
          Process.send_after(self(), :tick_timer, 1000)

          {:noreply,
           socket
           |> assign(:call, call)
           |> assign(:call_status, "active")}

        {:error, _} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("call_disconnected", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("call_ended_remote", _params, socket) do
    {:noreply,
     socket
     |> assign(:call_status, "ended")
     |> push_navigate(to: "/messages")}
  end

  def handle_event("call_declined_remote", _params, socket) do
    {:noreply,
     socket
     |> assign(:call_status, "declined")
     |> push_navigate(to: "/messages")}
  end

  def handle_event("mute_toggled", %{"muted" => muted}, socket) do
    {:noreply, assign(socket, :muted, muted)}
  end

  def handle_event("camera_toggled", %{"camera_off" => camera_off}, socket) do
    {:noreply, assign(socket, :camera_off, camera_off)}
  end

  def handle_event("media_error", _params, socket) do
    {:noreply, put_flash(socket, :error, "Could not access camera or microphone.")}
  end

  def handle_event("connection_state", _params, socket) do
    {:noreply, socket}
  end

  defp format_duration(seconds) do
    mins = div(seconds, 60)
    secs = rem(seconds, 60)
    String.pad_leading("#{mins}", 2, "0") <> ":" <> String.pad_leading("#{secs}", 2, "0")
  end

  def render(assigns) do
    ~H"""
    <div
      id="call-container"
      phx-hook="WebRTC"
      data-call-id={@call.id}
      data-user-id={@current_user.id}
      data-is-caller={"#{@is_caller}"}
      data-call-type={@call.call_type}
      data-turn-url={@turn_url}
      data-turn-api-key={@turn_api_key}
      class="fixed inset-0 z-50 flex flex-col bg-sa-black font-['DM_Sans']"
    >
      <%!-- Incoming call overlay (receiver sees this when status is ringing) --%>
      <%= if @call_status == "ringing" and not @is_caller do %>
        <div class="flex flex-col items-center justify-center flex-1 px-4">
          <%!-- Pulse rings behind avatar --%>
          <div class="relative mb-8">
            <div class="absolute inset-0 w-32 h-32 rounded-full bg-sa-green/20 animate-ping" />
            <div class="absolute inset-2 w-28 h-28 rounded-full bg-sa-green/30 animate-pulse" />
            <img
              src={@other_user.avatar_url || "/images/default_avatar.png"}
              alt={@other_user.display_name || @other_user.username}
              class="relative w-32 h-32 rounded-full object-cover border-4 border-sa-green"
            />
          </div>
          <h2 class="text-2xl text-sa-white font-['Sora'] font-semibold mb-2">
            {@other_user.display_name || @other_user.username}
          </h2>
          <p class="text-sa-gray-light text-sm mb-12">
            Incoming {@call.call_type} call...
          </p>
          <%!-- Accept / Decline buttons --%>
          <div class="flex items-center gap-12">
            <button
              phx-click="decline_call"
              class="flex flex-col items-center gap-2"
            >
              <div class="w-16 h-16 rounded-full bg-sa-red flex items-center justify-center hover:brightness-110 transition-all">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="w-8 h-8 text-white"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                >
                  <path
                    d="M10.68 13.31a16 16 0 0 0 3.41 2.6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7 2 2 0 0 1 1.72 2v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 2.59 3.4z"
                    transform="rotate(135 12 12)"
                  />
                </svg>
              </div>
              <span class="text-sa-red text-xs font-medium">Decline</span>
            </button>
            <button
              phx-click="accept_call"
              class="flex flex-col items-center gap-2"
            >
              <div class="w-16 h-16 rounded-full bg-sa-green flex items-center justify-center hover:brightness-110 transition-all">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="w-8 h-8 text-white"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                >
                  <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z" />
                </svg>
              </div>
              <span class="text-sa-green text-xs font-medium">Accept</span>
            </button>
          </div>
        </div>
      <% else %>
        <%!-- Active call / Caller waiting screen --%>
        <%!-- Top bar with caller info and duration --%>
        <div class="absolute top-0 left-0 right-0 z-20 flex items-center justify-between px-6 py-4 bg-gradient-to-b from-sa-black/80 to-transparent">
          <div class="flex items-center gap-3">
            <img
              src={@other_user.avatar_url || "/images/default_avatar.png"}
              alt={@other_user.display_name || @other_user.username}
              class="w-10 h-10 rounded-full object-cover border-2 border-sa-border"
            />
            <div>
              <p class="text-sa-white font-['Sora'] font-semibold text-sm">
                {@other_user.display_name || @other_user.username}
              </p>
              <p class="text-sa-gray-light text-xs">
                <%= if @call_status == "active" do %>
                  {format_duration(@call_duration)}
                <% else %>
                  <%= if @call_status == "ringing" do %>
                    Ringing...
                  <% else %>
                    {@call_status}
                  <% end %>
                <% end %>
              </p>
            </div>
          </div>
        </div>

        <%!-- Video / Voice area --%>
        <%= if @call.call_type == "video" do %>
          <%!-- Remote video full screen --%>
          <video
            id="remote-video"
            autoplay
            playsinline
            class="absolute inset-0 w-full h-full object-cover bg-sa-surface"
          />
          <%!-- Local video PiP --%>
          <div class="absolute top-20 right-4 z-10 w-32 h-44 rounded-xl overflow-hidden border-2 border-sa-border shadow-lg">
            <video
              id="local-video"
              autoplay
              playsinline
              muted
              class="w-full h-full object-cover bg-sa-surface2"
            />
          </div>
        <% else %>
          <%!-- Voice-only: large avatar with pulse --%>
          <div class="flex-1 flex flex-col items-center justify-center">
            <div class="relative mb-6">
              <%= if @call_status == "active" do %>
                <div class="absolute -inset-4 rounded-full bg-sa-green/15 animate-pulse" />
                <div
                  class="absolute -inset-8 rounded-full bg-sa-green/10 animate-ping"
                  style="animation-duration: 2s"
                />
              <% end %>
              <img
                src={@other_user.avatar_url || "/images/default_avatar.png"}
                alt={@other_user.display_name || @other_user.username}
                class="relative w-36 h-36 rounded-full object-cover border-4 border-sa-green"
              />
            </div>
            <h2 class="text-2xl text-sa-white font-['Sora'] font-semibold mb-1">
              {@other_user.display_name || @other_user.username}
            </h2>
            <p class="text-sa-gray-light text-sm">
              <%= if @call_status == "active" do %>
                {format_duration(@call_duration)}
              <% else %>
                <%= if @call_status == "ringing" do %>
                  Calling...
                <% else %>
                  {@call_status}
                <% end %>
              <% end %>
            </p>
            <%!-- Hidden audio element for voice calls --%>
            <audio id="remote-audio" autoplay class="hidden" />
            <audio id="local-video" autoplay muted class="hidden" />
          </div>
        <% end %>

        <%!-- Bottom control bar --%>
        <div class="absolute bottom-0 left-0 right-0 z-20 flex items-center justify-center gap-6 px-6 py-8 bg-gradient-to-t from-sa-black/80 to-transparent">
          <%!-- Mute button --%>
          <button
            phx-click="toggle_mute"
            class={[
              "w-14 h-14 rounded-full flex items-center justify-center transition-all",
              if(@muted, do: "bg-sa-white/20", else: "bg-sa-surface2 border border-sa-border")
            ]}
          >
            <%= if @muted do %>
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="w-6 h-6 text-sa-red"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
              >
                <line x1="1" y1="1" x2="23" y2="23" />
                <path d="M9 9v3a3 3 0 0 0 5.12 2.12M15 9.34V4a3 3 0 0 0-5.94-.6" />
                <path d="M17 16.95A7 7 0 0 1 5 12v-2m14 0v2c0 .76-.13 1.49-.36 2.18" />
                <line x1="12" y1="19" x2="12" y2="23" />
                <line x1="8" y1="23" x2="16" y2="23" />
              </svg>
            <% else %>
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="w-6 h-6 text-sa-white"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
              >
                <path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z" />
                <path d="M19 10v2a7 7 0 0 1-14 0v-2" />
                <line x1="12" y1="19" x2="12" y2="23" />
                <line x1="8" y1="23" x2="16" y2="23" />
              </svg>
            <% end %>
          </button>

          <%!-- Camera toggle (only for video calls) --%>
          <%= if @call.call_type == "video" do %>
            <button
              phx-click="toggle_camera"
              class={[
                "w-14 h-14 rounded-full flex items-center justify-center transition-all",
                if(@camera_off, do: "bg-sa-white/20", else: "bg-sa-surface2 border border-sa-border")
              ]}
            >
              <%= if @camera_off do %>
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="w-6 h-6 text-sa-red"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                >
                  <path d="M16 16v1a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2h2m5.66 0H14a2 2 0 0 1 2 2v3.34l1 1L23 7v10" />
                  <line x1="1" y1="1" x2="23" y2="23" />
                </svg>
              <% else %>
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="w-6 h-6 text-sa-white"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                >
                  <polygon points="23 7 16 12 23 17 23 7" />
                  <rect x="1" y="5" width="15" height="14" rx="2" ry="2" />
                </svg>
              <% end %>
            </button>
          <% end %>

          <%!-- End call button --%>
          <button
            phx-click="end_call"
            class="w-16 h-16 rounded-full bg-sa-red flex items-center justify-center hover:brightness-110 transition-all"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="w-7 h-7 text-white"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
            >
              <path
                d="M10.68 13.31a16 16 0 0 0 3.41 2.6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7 2 2 0 0 1 1.72 2v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 2.59 3.4z"
                transform="rotate(135 12 12)"
              />
            </svg>
          </button>

          <%!-- Speaker button --%>
          <button class="w-14 h-14 rounded-full bg-sa-surface2 border border-sa-border flex items-center justify-center transition-all">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="w-6 h-6 text-sa-white"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
            >
              <polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5" />
              <path d="M19.07 4.93a10 10 0 0 1 0 14.14M15.54 8.46a5 5 0 0 1 0 7.07" />
            </svg>
          </button>
        </div>
      <% end %>
    </div>
    """
  end
end
