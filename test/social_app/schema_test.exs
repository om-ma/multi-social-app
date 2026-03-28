defmodule SocialApp.SchemaTest do
  use SocialApp.DataCase, async: true

  alias SocialApp.Repo

  describe "database tables exist" do
    test "users table" do
      assert {:ok, _} = Repo.query("SELECT count(*) FROM users")
    end

    test "posts table" do
      assert {:ok, _} = Repo.query("SELECT count(*) FROM posts")
    end

    test "stories table" do
      assert {:ok, _} = Repo.query("SELECT count(*) FROM stories")
    end

    test "likes table" do
      assert {:ok, _} = Repo.query("SELECT count(*) FROM likes")
    end

    test "reels table" do
      assert {:ok, _} = Repo.query("SELECT count(*) FROM reels")
    end

    test "conversations table" do
      assert {:ok, _} = Repo.query("SELECT count(*) FROM conversations")
    end

    test "conversation_members table" do
      assert {:ok, _} = Repo.query("SELECT count(*) FROM conversation_members")
    end

    test "messages table" do
      assert {:ok, _} = Repo.query("SELECT count(*) FROM messages")
    end

    test "calls table" do
      assert {:ok, _} = Repo.query("SELECT count(*) FROM calls")
    end

    test "follows table" do
      assert {:ok, _} = Repo.query("SELECT count(*) FROM follows")
    end

    test "notifications table" do
      assert {:ok, _} = Repo.query("SELECT count(*) FROM notifications")
    end
  end

  describe "unique constraints" do
    test "likes unique on user_id + post_id" do
      result =
        Repo.query!(
          "SELECT indexname FROM pg_indexes WHERE tablename = 'likes' AND indexname LIKE '%user_id_post_id%'"
        )

      assert length(result.rows) == 1
    end

    test "follows unique on follower_id + following_id" do
      result =
        Repo.query!(
          "SELECT indexname FROM pg_indexes WHERE tablename = 'follows' AND indexname LIKE '%follower_id_following_id%'"
        )

      assert length(result.rows) == 1
    end

    test "conversation_members unique on conversation_id + user_id" do
      result =
        Repo.query!(
          "SELECT indexname FROM pg_indexes WHERE tablename = 'conversation_members' AND indexname LIKE '%conversation_id_user_id%'"
        )

      assert length(result.rows) == 1
    end
  end

  describe "foreign keys" do
    test "posts references users" do
      result =
        Repo.query!("""
          SELECT constraint_name FROM information_schema.table_constraints
          WHERE table_name = 'posts' AND constraint_type = 'FOREIGN KEY'
        """)

      assert length(result.rows) >= 1
    end

    test "messages references conversations and users" do
      result =
        Repo.query!("""
          SELECT constraint_name FROM information_schema.table_constraints
          WHERE table_name = 'messages' AND constraint_type = 'FOREIGN KEY'
        """)

      assert length(result.rows) >= 2
    end

    test "calls references users (caller and receiver)" do
      result =
        Repo.query!("""
          SELECT constraint_name FROM information_schema.table_constraints
          WHERE table_name = 'calls' AND constraint_type = 'FOREIGN KEY'
        """)

      assert length(result.rows) >= 2
    end
  end
end
