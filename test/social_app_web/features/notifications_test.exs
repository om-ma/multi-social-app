defmodule SocialAppWeb.Features.NotificationsTest do
  use SocialAppWeb.FeatureCase, async: false
  @moduletag :browser

  alias SocialApp.Social

  describe "notifications page" do
    test "notifications page loads with header", %{session: session} do
      user = create_test_user()

      session
      |> login(user)
      |> assert_has(css("h1", text: "Feed"))
      |> visit("/notifications")
      |> assert_has(css("h1", text: "Notifications"))
    end

    test "notifications page shows empty state when no notifications", %{session: session} do
      user = create_test_user()

      session
      |> login(user)
      |> assert_has(css("h1", text: "Feed"))
      |> visit("/notifications")
      |> assert_has(css("p", text: "No notifications yet"))
    end

    test "notifications show follow notification when user was followed", %{session: session} do
      user = create_test_user(%{"display_name" => "NotifTarget"})
      follower = create_test_user(%{"display_name" => "FollowerActor"})

      # Follow to generate a notification
      Social.follow(follower.id, user.id)

      session
      |> login(user)
      |> assert_has(css("h1", text: "Feed"))
      |> visit("/notifications")
      |> assert_has(css("h1", text: "Notifications"))
      |> assert_has(css("span", text: "started following you"))
    end
  end
end
