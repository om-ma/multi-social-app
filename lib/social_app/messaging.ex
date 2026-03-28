defmodule SocialApp.Messaging do
  @moduledoc """
  The Messaging context for conversations and messages.
  """

  import Ecto.Query
  alias SocialApp.Repo
  alias SocialApp.Messaging.{Conversation, ConversationMember, Message}

  # ── Conversations ──

  def list_conversations(user_id) do
    last_message_query =
      from m in Message,
        where: m.conversation_id == parent_as(:conversation).id,
        order_by: [desc: m.inserted_at],
        limit: 1

    from(c in Conversation,
      as: :conversation,
      join: cm in ConversationMember,
      on: cm.conversation_id == c.id,
      where: cm.user_id == ^user_id,
      left_lateral_join: lm in subquery(last_message_query),
      on: true,
      preload: [members: :user],
      order_by: [desc_nulls_last: lm.inserted_at],
      select_merge: %{id: c.id}
    )
    |> Repo.all()
    |> Enum.map(fn conv ->
      last_msg =
        from(m in Message,
          where: m.conversation_id == ^conv.id,
          order_by: [desc: m.inserted_at],
          limit: 1,
          preload: [:sender]
        )
        |> Repo.one()

      Map.put(conv, :last_message, last_msg)
    end)
  end

  def get_conversation!(conversation_id, user_id) do
    conversation =
      from(c in Conversation,
        join: cm in ConversationMember,
        on: cm.conversation_id == c.id,
        where: c.id == ^conversation_id and cm.user_id == ^user_id,
        preload: [members: :user]
      )
      |> Repo.one!()

    conversation
  end

  def create_dm(user_id_1, user_id_2) do
    # Check for existing DM between these two users
    existing =
      from(c in Conversation,
        where: c.is_group == false,
        join: cm1 in ConversationMember,
        on: cm1.conversation_id == c.id and cm1.user_id == ^user_id_1,
        join: cm2 in ConversationMember,
        on: cm2.conversation_id == c.id and cm2.user_id == ^user_id_2,
        preload: [members: :user]
      )
      |> Repo.one()

    case existing do
      nil ->
        Repo.transaction(fn ->
          {:ok, conv} =
            %Conversation{}
            |> Conversation.changeset(%{is_group: false})
            |> Repo.insert()

          now = DateTime.utc_now() |> DateTime.truncate(:second)

          for uid <- [user_id_1, user_id_2] do
            %ConversationMember{}
            |> ConversationMember.changeset(%{
              conversation_id: conv.id,
              user_id: uid,
              joined_at: now
            })
            |> Repo.insert!()
          end

          conv |> Repo.preload(members: :user)
        end)

      conv ->
        {:ok, conv}
    end
  end

  def create_group(creator_id, name, member_ids) do
    all_member_ids = Enum.uniq([creator_id | member_ids])

    Repo.transaction(fn ->
      {:ok, conv} =
        %Conversation{}
        |> Conversation.changeset(%{is_group: true, name: name})
        |> Repo.insert()

      now = DateTime.utc_now() |> DateTime.truncate(:second)

      for uid <- all_member_ids do
        %ConversationMember{}
        |> ConversationMember.changeset(%{
          conversation_id: conv.id,
          user_id: uid,
          joined_at: now
        })
        |> Repo.insert!()
      end

      conv |> Repo.preload(members: :user)
    end)
  end

  # ── Messages ──

  def list_messages(conversation_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    before_id = Keyword.get(opts, :before)

    query =
      from(m in Message,
        where: m.conversation_id == ^conversation_id,
        order_by: [desc: m.inserted_at, desc: m.id],
        limit: ^limit,
        preload: [:sender]
      )

    query =
      if before_id do
        from(m in query, where: m.id < ^before_id)
      else
        query
      end

    query
    |> Repo.all()
    |> Enum.reverse()
  end

  def send_message(conversation_id, sender_id, attrs) do
    %Message{}
    |> Message.changeset(
      Map.merge(attrs, %{
        "conversation_id" => conversation_id,
        "sender_id" => sender_id
      })
    )
    |> Repo.insert()
    |> case do
      {:ok, message} ->
        message = Repo.preload(message, :sender)

        Phoenix.PubSub.broadcast(
          SocialApp.PubSub,
          "conversation:#{conversation_id}",
          {:new_message, message}
        )

        {:ok, message}

      error ->
        error
    end
  end

  def mark_as_read(conversation_id, user_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    from(m in Message,
      where:
        m.conversation_id == ^conversation_id and
          m.sender_id != ^user_id and
          is_nil(m.read_at)
    )
    |> Repo.update_all(set: [read_at: now])
  end

  def unread_count(user_id) do
    from(m in Message,
      join: cm in ConversationMember,
      on: cm.conversation_id == m.conversation_id,
      where:
        cm.user_id == ^user_id and
          m.sender_id != ^user_id and
          is_nil(m.read_at)
    )
    |> Repo.aggregate(:count)
  end

  def unread_count_for_conversation(conversation_id, user_id) do
    from(m in Message,
      where:
        m.conversation_id == ^conversation_id and
          m.sender_id != ^user_id and
          is_nil(m.read_at)
    )
    |> Repo.aggregate(:count)
  end

  def subscribe_conversation(conversation_id) do
    Phoenix.PubSub.subscribe(SocialApp.PubSub, "conversation:#{conversation_id}")
  end

  def broadcast_typing(conversation_id, user) do
    Phoenix.PubSub.broadcast(SocialApp.PubSub, "conversation:#{conversation_id}", {:typing, user})
  end

  def broadcast_stop_typing(conversation_id, user) do
    Phoenix.PubSub.broadcast(
      SocialApp.PubSub,
      "conversation:#{conversation_id}",
      {:stop_typing, user}
    )
  end
end
