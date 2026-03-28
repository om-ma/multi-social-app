defmodule SocialAppWeb.Features.ReelsTest do
  use SocialAppWeb.FeatureCase, async: false

  alias SocialApp.Reels

  describe "reels page" do
    test "reels page loads with For You tab active by default", %{session: session} do
      user = create_test_user()

      session
      |> login(user)
      |> assert_has(css("h1", text: "Feed"))
      |> visit("/reels")
      |> assert_has(css("button", text: "For You"))
      |> assert_has(css("button", text: "Following"))
    end

    test "reels page shows empty state when no reels", %{session: session} do
      user = create_test_user()

      session
      |> login(user)
      |> assert_has(css("h1", text: "Feed"))
      |> visit("/reels")
      |> assert_has(css("p", text: "No reels yet"))
    end

    test "switch to Following tab", %{session: session} do
      user = create_test_user()

      session
      |> login(user)
      |> assert_has(css("h1", text: "Feed"))
      |> visit("/reels")
      |> click(css("button", text: "Following"))
      |> assert_has(css("button", text: "Following"))
    end

    test "switch to Following tab shows no following reels message", %{session: session} do
      user = create_test_user()

      session
      |> login(user)
      |> assert_has(css("h1", text: "Feed"))
      |> visit("/reels")
      |> click(css("button", text: "Following"))
      |> assert_has(css("p", text: "Follow some users to see their reels"))
    end

    test "reel content is visible when reels exist", %{session: session} do
      user = create_test_user()

      {:ok, _reel} =
        Reels.create_reel(user, %{
          "video_url" => "https://placeholder.test/video.mp4",
          "caption" => "My first reel"
        })

      session
      |> login(user)
      |> assert_has(css("h1", text: "Feed"))
      |> visit("/reels")
      |> assert_has(css("p", text: "My first reel"))
    end

    test "upload reel modal opens and submits", %{session: session} do
      user = create_test_user()

      session
      |> login(user)
      |> assert_has(css("h1", text: "Feed"))
      |> visit("/reels")
      |> assert_has(css("button", text: "For You"))
      |> click(css("button[phx-click='open_upload_modal']"))
      |> assert_has(css("h2", text: "Create Reel"))
      |> fill_in(css("textarea[name='caption']"), with: "My new reel caption")
      |> click(button("Post Reel"))
      |> assert_has(css("p", text: "My new reel caption"))
    end

    test "like a reel updates count", %{session: session} do
      user = create_test_user()

      {:ok, _reel} =
        Reels.create_reel(user, %{
          "video_url" => "https://placeholder.test/video.mp4",
          "caption" => "Likeable reel"
        })

      session
      |> login(user)
      |> assert_has(css("h1", text: "Feed"))
      |> visit("/reels")
      |> assert_has(css("#reels-container"))
      |> assert_has(css(".reel-item"))
      |> click(css("button[phx-click='toggle_like']"))
      |> assert_has(css("span", text: "1"))
    end
  end
end
