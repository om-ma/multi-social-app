defmodule SocialAppWeb.Features.ExploreTest do
  use SocialAppWeb.FeatureCase, async: false
  @moduletag :browser

  describe "explore page" do
    test "explore page loads with header and search bar", %{session: session} do
      user = create_test_user()

      session
      |> login(user)
      |> assert_has(css("h1", text: "Feed"))
      |> visit("/explore")
      |> assert_has(css("h1", text: "Explore"))
      |> assert_has(css("input[name='query']"))
    end

    test "explore page shows suggested users section", %{session: session} do
      user = create_test_user()
      _other = create_test_user(%{"display_name" => "SuggestedPerson"})

      session
      |> login(user)
      |> assert_has(css("h1", text: "Feed"))
      |> visit("/explore")
      |> assert_has(css("h1", text: "Explore"))
      |> assert_has(css("h2"))
    end

    test "suggested user has follow button on explore page", %{session: session} do
      user = create_test_user()
      other = create_test_user(%{"display_name" => "FollowableUser"})

      session
      |> login(user)
      |> assert_has(css("h1", text: "Feed"))
      |> visit("/explore")
      |> assert_has(css("h1", text: "Explore"))
      |> assert_has(css("button[phx-value-id='#{other.id}']", text: "Follow", count: :any))
    end
  end
end
