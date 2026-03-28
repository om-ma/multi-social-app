defmodule SocialAppWeb.NavShell do
  @moduledoc """
  on_mount hook that attaches navigation shell data to all authenticated LiveViews.
  Sets up sidebar badges, search, create post modal, and PubSub subscriptions
  for real-time badge updates.
  """
  import Phoenix.LiveView
  import Phoenix.Component

  alias SocialApp.Social
  alias SocialApp.Messaging

  def on_mount(:default, _params, _session, socket) do
    if connected?(socket) do
      user = socket.assigns[:current_user]

      if user do
        # Subscribe for real-time badge updates
        Phoenix.PubSub.subscribe(SocialApp.PubSub, "user:#{user.id}:notifications")
        Phoenix.PubSub.subscribe(SocialApp.PubSub, "user:#{user.id}:messages")

        # Schedule periodic badge refresh
        Process.send_after(self(), :refresh_nav_badges, 60_000)
      end
    end

    user = socket.assigns[:current_user]

    if user do
      unread_notifications = safe_unread_notification_count(user.id)
      unread_messages = safe_unread_message_count(user.id)
      stories_by_user = safe_list_stories()

      socket =
        socket
        |> assign(:nav_unread_notifications, unread_notifications)
        |> assign(:nav_unread_messages, unread_messages)
        |> assign(:nav_stories_by_user, stories_by_user)
        |> assign(:show_create_post, socket.assigns[:show_create_post] || false)
        |> assign(:nav_search_query, "")
        |> assign(:nav_search_results, [])
        |> assign(:nav_current_path, current_path(socket))
        |> attach_hook(:nav_handle_params, :handle_params, &handle_params/3)
        |> attach_hook(:nav_handle_event, :handle_event, &handle_event/3)
        |> attach_hook(:nav_handle_info, :handle_info, &handle_info/2)

      {:cont, socket}
    else
      {:cont, socket}
    end
  end

  defp handle_params(_params, uri, socket) do
    path = URI.parse(uri).path || "/"
    {:cont, assign(socket, :nav_current_path, path)}
  end

  defp handle_event("noop", _params, socket) do
    {:halt, socket}
  end

  defp handle_event("open_create_post", _params, socket) do
    {:halt, assign(socket, :show_create_post, true)}
  end

  defp handle_event("close_create_post", _params, socket) do
    {:halt, assign(socket, :show_create_post, false)}
  end

  defp handle_event("create_post", %{"content" => content} = params, socket) do
    attrs =
      %{"content" => content}
      |> maybe_put_media(params)

    case SocialApp.Feed.create_post(socket.assigns.current_user.id, attrs) do
      {:ok, _post} ->
        socket =
          socket
          |> assign(:show_create_post, false)
          |> Phoenix.LiveView.put_flash(:info, "Post created!")
          |> Phoenix.LiveView.push_navigate(to: "/feed")

        {:halt, socket}

      {:error, _changeset} ->
        {:halt, Phoenix.LiveView.put_flash(socket, :error, "Could not create post.")}
    end
  end

  defp handle_event("sidebar_search", %{"value" => query}, socket) do
    query = String.trim(query)

    if query == "" do
      {:halt, assign(socket, nav_search_query: "", nav_search_results: [])}
    else
      results = Social.search_users(query) |> Enum.take(8)
      {:halt, assign(socket, nav_search_query: query, nav_search_results: results)}
    end
  end

  defp handle_event(_event, _params, socket) do
    {:cont, socket}
  end

  defp handle_info(:refresh_nav_badges, socket) do
    user = socket.assigns[:current_user]

    if user do
      Process.send_after(self(), :refresh_nav_badges, 60_000)

      socket =
        socket
        |> assign(:nav_unread_notifications, safe_unread_notification_count(user.id))
        |> assign(:nav_unread_messages, safe_unread_message_count(user.id))

      {:cont, socket}
    else
      {:cont, socket}
    end
  end

  defp handle_info({:new_notification, _notification}, socket) do
    user = socket.assigns[:current_user]

    if user do
      {:cont, assign(socket, :nav_unread_notifications, safe_unread_notification_count(user.id))}
    else
      {:cont, socket}
    end
  end

  defp handle_info({:new_message, _message}, socket) do
    user = socket.assigns[:current_user]

    if user do
      {:cont, assign(socket, :nav_unread_messages, safe_unread_message_count(user.id))}
    else
      {:cont, socket}
    end
  end

  defp handle_info(_msg, socket) do
    {:cont, socket}
  end

  defp current_path(socket) do
    case socket.assigns do
      %{__changed__: _} -> "/"
      _ -> "/"
    end
  end

  defp safe_unread_notification_count(user_id) do
    Social.unread_notification_count(user_id)
  rescue
    _ -> 0
  end

  defp safe_unread_message_count(user_id) do
    Messaging.unread_count(user_id)
  rescue
    _ -> 0
  end

  defp safe_list_stories do
    SocialApp.Feed.list_active_stories()
  rescue
    _ -> %{}
  end

  defp maybe_put_media(attrs, %{"media_type" => media_type})
       when media_type in ["image", "video"] do
    Map.merge(attrs, %{"media_type" => media_type, "media_url" => "placeholder://#{media_type}"})
  end

  defp maybe_put_media(attrs, _params), do: attrs
end
