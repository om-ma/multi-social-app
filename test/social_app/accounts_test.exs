defmodule SocialApp.AccountsTest do
  use SocialApp.DataCase, async: true

  alias SocialApp.Accounts
  alias SocialApp.Accounts.User

  @valid_attrs %{
    "username" => "testuser",
    "email" => "test@example.com",
    "display_name" => "Test User",
    "password" => "password123"
  }

  describe "register_user/1" do
    test "creates user with valid attributes" do
      assert {:ok, %User{} = user} = Accounts.register_user(@valid_attrs)
      assert user.username == "testuser"
      assert user.email == "test@example.com"
      assert user.display_name == "Test User"
      assert user.hashed_password != nil
      assert user.followers_count == 0
      assert user.following_count == 0
      assert user.posts_count == 0
    end

    test "hashes the password" do
      {:ok, user} = Accounts.register_user(@valid_attrs)
      assert user.hashed_password != "password123"
      assert Bcrypt.verify_pass("password123", user.hashed_password)
    end

    test "rejects duplicate username" do
      {:ok, _} = Accounts.register_user(@valid_attrs)

      {:error, changeset} =
        Accounts.register_user(%{@valid_attrs | "email" => "other@example.com"})

      assert "has already been taken" in errors_on(changeset).username
    end

    test "rejects duplicate email" do
      {:ok, _} = Accounts.register_user(@valid_attrs)
      {:error, changeset} = Accounts.register_user(%{@valid_attrs | "username" => "otheruser"})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "rejects email that is case-different duplicate" do
      {:ok, _} = Accounts.register_user(@valid_attrs)

      {:error, changeset} =
        Accounts.register_user(%{
          @valid_attrs
          | "username" => "otheruser",
            "email" => "TEST@example.com"
        })

      assert "has already been taken" in errors_on(changeset).email
    end

    test "rejects short password" do
      attrs = %{@valid_attrs | "password" => "12345"}
      {:error, changeset} = Accounts.register_user(attrs)
      assert "should be at least 6 character(s)" in errors_on(changeset).password
    end

    test "rejects missing required fields" do
      {:error, changeset} = Accounts.register_user(%{})
      assert "can't be blank" in errors_on(changeset).username
      assert "can't be blank" in errors_on(changeset).email
      assert "can't be blank" in errors_on(changeset).password
    end

    test "rejects invalid username format" do
      attrs = %{@valid_attrs | "username" => "bad user!"}
      {:error, changeset} = Accounts.register_user(attrs)
      assert "only letters, numbers, dots, and underscores" in errors_on(changeset).username
    end

    test "rejects invalid email format" do
      attrs = %{@valid_attrs | "email" => "not-an-email"}
      {:error, changeset} = Accounts.register_user(attrs)
      assert "must be a valid email" in errors_on(changeset).email
    end
  end

  describe "authenticate/2" do
    setup do
      {:ok, user} = Accounts.register_user(@valid_attrs)
      %{user: user}
    end

    test "returns user with correct credentials", %{user: user} do
      assert {:ok, authenticated} = Accounts.authenticate("test@example.com", "password123")
      assert authenticated.id == user.id
    end

    test "returns error with wrong password" do
      assert {:error, :invalid_password} =
               Accounts.authenticate("test@example.com", "wrongpassword")
    end

    test "returns error with non-existent email" do
      assert {:error, :not_found} = Accounts.authenticate("nobody@example.com", "password123")
    end
  end

  describe "get_user!/1" do
    test "returns user by id" do
      {:ok, user} = Accounts.register_user(@valid_attrs)
      assert Accounts.get_user!(user.id).id == user.id
    end

    test "raises on invalid id" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(0)
      end
    end
  end

  describe "get_user_by_email/1" do
    test "returns user by email" do
      {:ok, user} = Accounts.register_user(@valid_attrs)
      assert Accounts.get_user_by_email("test@example.com").id == user.id
    end

    test "returns nil for unknown email" do
      assert Accounts.get_user_by_email("nobody@example.com") == nil
    end
  end

  describe "get_user_by_username/1" do
    test "returns user by username" do
      {:ok, user} = Accounts.register_user(@valid_attrs)
      assert Accounts.get_user_by_username("testuser").id == user.id
    end

    test "returns nil for unknown username" do
      assert Accounts.get_user_by_username("nobody") == nil
    end
  end
end
