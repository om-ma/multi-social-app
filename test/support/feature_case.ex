defmodule SocialAppWeb.FeatureCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.Feature
      import Wallaby.Query
      alias SocialApp.Repo
      alias SocialApp.Accounts

      @endpoint SocialAppWeb.Endpoint

      def create_test_user(attrs \\ %{}) do
        default = %{
          "username" => "testuser_#{System.unique_integer([:positive])}",
          "email" => "test_#{System.unique_integer([:positive])}@example.com",
          "password" => "password123",
          "display_name" => "Test User"
        }

        {:ok, user} = Accounts.register_user(Map.merge(default, attrs))
        user
      end

      def login(session, user) do
        session
        |> visit("/login")
        |> fill_in(css("input[name='email']"), with: user.email)
        |> fill_in(css("input[name='password']"), with: "password123")
        |> click(button("Sign In"))
      end
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(SocialApp.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(SocialApp.Repo, {:shared, self()})
    end

    metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(SocialApp.Repo, self())
    {:ok, session} = Wallaby.start_session(metadata: metadata)
    {:ok, session: session}
  end
end
