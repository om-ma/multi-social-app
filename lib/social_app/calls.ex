defmodule SocialApp.Calls do
  @moduledoc """
  The Calls context for managing video and voice calls.
  """

  import Ecto.Query
  alias SocialApp.Repo
  alias SocialApp.Calls.Call

  @doc """
  Creates a new call record.
  """
  def create_call(attrs) do
    %Call{}
    |> Call.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates the status of a call.
  """
  def update_call_status(%Call{} = call, status) do
    attrs =
      case status do
        "active" ->
          %{status: status, started_at: DateTime.utc_now() |> DateTime.truncate(:second)}

        "ended" ->
          %{status: status, ended_at: DateTime.utc_now() |> DateTime.truncate(:second)}

        _ ->
          %{status: status}
      end

    call
    |> Call.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Ends a call by setting status to ended and ended_at timestamp.
  """
  def end_call(%Call{} = call) do
    call
    |> Call.changeset(%{
      status: "ended",
      ended_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
    |> Repo.update()
  end

  @doc """
  Lists call history for a user (as caller or receiver), preloading the other user.
  Ordered by inserted_at desc.
  """
  def list_call_history(user_id) do
    Call
    |> where([c], c.caller_id == ^user_id or c.receiver_id == ^user_id)
    |> order_by([c], desc: c.inserted_at)
    |> preload([:caller, :receiver])
    |> Repo.all()
  end

  @doc """
  Gets a call by ID with preloaded caller and receiver.
  Raises if not found.
  """
  def get_call!(id) do
    Call
    |> preload([:caller, :receiver])
    |> Repo.get!(id)
  end
end
