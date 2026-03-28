defmodule SocialAppWeb.CallChannel do
  use SocialAppWeb, :channel

  alias SocialApp.Calls

  @impl true
  def join("call:" <> call_id, _payload, socket) do
    call_id = String.to_integer(call_id)
    user_id = socket.assigns.user_id

    try do
      call = Calls.get_call!(call_id)

      if call.caller_id == user_id or call.receiver_id == user_id do
        socket =
          socket
          |> assign(:call_id, call_id)
          |> assign(:call, call)

        {:ok, socket}
      else
        {:error, %{reason: "unauthorized"}}
      end
    rescue
      Ecto.NoResultsError ->
        {:error, %{reason: "not_found"}}
    end
  end

  @impl true
  def handle_in("offer", %{"sdp" => sdp}, socket) do
    broadcast_from!(socket, "offer", %{sdp: sdp, from: socket.assigns.user_id})
    {:noreply, socket}
  end

  @impl true
  def handle_in("answer", %{"sdp" => sdp}, socket) do
    broadcast_from!(socket, "answer", %{sdp: sdp, from: socket.assigns.user_id})
    {:noreply, socket}
  end

  @impl true
  def handle_in("ice_candidate", %{"candidate" => candidate}, socket) do
    broadcast_from!(socket, "ice_candidate", %{
      candidate: candidate,
      from: socket.assigns.user_id
    })

    {:noreply, socket}
  end

  @impl true
  def handle_in("call_end", _payload, socket) do
    call = Calls.get_call!(socket.assigns.call_id)

    if call.status in ["ringing", "active"] do
      Calls.end_call(call)
    end

    broadcast!(socket, "call_ended", %{ended_by: socket.assigns.user_id})
    {:noreply, socket}
  end

  @impl true
  def handle_in("call_decline", _payload, socket) do
    call = Calls.get_call!(socket.assigns.call_id)

    if call.status == "ringing" do
      Calls.update_call_status(call, "declined")
    end

    broadcast!(socket, "call_declined", %{declined_by: socket.assigns.user_id})
    {:noreply, socket}
  end
end
