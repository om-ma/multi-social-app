defmodule SocialApp.CallsTest do
  use SocialApp.DataCase

  alias SocialApp.Calls
  alias SocialApp.Calls.Call
  alias SocialApp.Accounts

  defp create_user(attrs) do
    {:ok, user} =
      Accounts.register_user(
        Map.merge(
          %{
            username: "user_#{System.unique_integer([:positive])}",
            email: "user_#{System.unique_integer([:positive])}@test.com",
            password: "password123",
            display_name: "Test User"
          },
          attrs
        )
      )

    user
  end

  defp create_test_call(caller, receiver, attrs \\ %{}) do
    {:ok, call} =
      Calls.create_call(
        Map.merge(
          %{
            caller_id: caller.id,
            receiver_id: receiver.id,
            call_type: "video"
          },
          attrs
        )
      )

    call
  end

  describe "create_call/1" do
    test "creates a call with valid attributes" do
      caller = create_user(%{username: "caller1", email: "caller1@test.com"})
      receiver = create_user(%{username: "receiver1", email: "receiver1@test.com"})

      assert {:ok, %Call{} = call} =
               Calls.create_call(%{
                 caller_id: caller.id,
                 receiver_id: receiver.id,
                 call_type: "video"
               })

      assert call.caller_id == caller.id
      assert call.receiver_id == receiver.id
      assert call.call_type == "video"
      assert call.status == "ringing"
    end

    test "creates a voice call" do
      caller = create_user(%{username: "caller2", email: "caller2@test.com"})
      receiver = create_user(%{username: "receiver2", email: "receiver2@test.com"})

      assert {:ok, %Call{} = call} =
               Calls.create_call(%{
                 caller_id: caller.id,
                 receiver_id: receiver.id,
                 call_type: "voice"
               })

      assert call.call_type == "voice"
    end

    test "fails with invalid call_type" do
      caller = create_user(%{username: "caller3", email: "caller3@test.com"})
      receiver = create_user(%{username: "receiver3", email: "receiver3@test.com"})

      assert {:error, changeset} =
               Calls.create_call(%{
                 caller_id: caller.id,
                 receiver_id: receiver.id,
                 call_type: "text"
               })

      assert %{call_type: _} = errors_on(changeset)
    end

    test "fails without required fields" do
      assert {:error, changeset} = Calls.create_call(%{})
      errors = errors_on(changeset)
      assert Map.has_key?(errors, :caller_id)
      assert Map.has_key?(errors, :receiver_id)
      assert Map.has_key?(errors, :call_type)
    end
  end

  describe "update_call_status/2" do
    test "updates status to active and sets started_at" do
      caller = create_user(%{username: "caller4", email: "caller4@test.com"})
      receiver = create_user(%{username: "receiver4", email: "receiver4@test.com"})
      call = create_test_call(caller, receiver)

      assert {:ok, %Call{} = updated} = Calls.update_call_status(call, "active")
      assert updated.status == "active"
      assert updated.started_at != nil
    end

    test "updates status to ended and sets ended_at" do
      caller = create_user(%{username: "caller5", email: "caller5@test.com"})
      receiver = create_user(%{username: "receiver5", email: "receiver5@test.com"})
      call = create_test_call(caller, receiver)

      assert {:ok, %Call{} = updated} = Calls.update_call_status(call, "ended")
      assert updated.status == "ended"
      assert updated.ended_at != nil
    end

    test "updates status to declined" do
      caller = create_user(%{username: "caller6", email: "caller6@test.com"})
      receiver = create_user(%{username: "receiver6", email: "receiver6@test.com"})
      call = create_test_call(caller, receiver)

      assert {:ok, %Call{} = updated} = Calls.update_call_status(call, "declined")
      assert updated.status == "declined"
    end
  end

  describe "end_call/1" do
    test "ends a call setting status and ended_at" do
      caller = create_user(%{username: "caller7", email: "caller7@test.com"})
      receiver = create_user(%{username: "receiver7", email: "receiver7@test.com"})
      call = create_test_call(caller, receiver)

      assert {:ok, %Call{} = ended} = Calls.end_call(call)
      assert ended.status == "ended"
      assert ended.ended_at != nil
    end
  end

  describe "get_call!/1" do
    test "returns call with preloaded users" do
      caller = create_user(%{username: "caller8", email: "caller8@test.com"})
      receiver = create_user(%{username: "receiver8", email: "receiver8@test.com"})
      call = create_test_call(caller, receiver)

      fetched = Calls.get_call!(call.id)
      assert fetched.id == call.id
      assert fetched.caller.id == caller.id
      assert fetched.receiver.id == receiver.id
    end

    test "raises for non-existent call" do
      assert_raise Ecto.NoResultsError, fn ->
        Calls.get_call!(0)
      end
    end
  end

  describe "list_call_history/1" do
    test "lists calls for a user ordered by inserted_at desc" do
      caller = create_user(%{username: "caller9", email: "caller9@test.com"})
      receiver = create_user(%{username: "receiver9", email: "receiver9@test.com"})
      other = create_user(%{username: "other9", email: "other9@test.com"})

      _call1 = create_test_call(caller, receiver)
      _call2 = create_test_call(receiver, caller, %{call_type: "voice"})
      _call3 = create_test_call(other, create_user(%{username: "other_x9", email: "x9@test.com"}))

      history = Calls.list_call_history(caller.id)
      assert length(history) == 2
      assert Enum.all?(history, fn c -> c.caller.id != nil and c.receiver.id != nil end)
    end

    test "returns empty list for user with no calls" do
      user = create_user(%{username: "lonely", email: "lonely@test.com"})
      assert Calls.list_call_history(user.id) == []
    end
  end
end
