defmodule SocialAppWeb.ProfileEditLive do
  use SocialAppWeb, :live_view

  alias SocialApp.Accounts

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    changeset = Accounts.change_profile(user)

    {:ok,
     socket
     |> assign(:page_title, "Edit Profile")
     |> assign(:changeset, changeset)
     |> assign(:user, user)}
  end

  @impl true
  def handle_event("validate", %{"user" => params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_profile(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"user" => params}, socket) do
    case Accounts.update_user(socket.assigns.user, params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(:user, user)
         |> assign(:current_user, user)
         |> assign(:changeset, Accounts.change_profile(user))
         |> put_flash(:info, "Profile updated!")}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-sa-black">
      <div class="max-w-lg mx-auto px-4 py-8">
        <h1 class="text-2xl font-bold font-['Sora'] text-sa-white mb-6">Edit Profile</h1>

        <.form for={@changeset} phx-change="validate" phx-submit="save" class="space-y-5">
          <div>
            <label class="block text-sm text-sa-gray-light font-['DM_Sans'] mb-1">Display Name</label>
            <input
              type="text"
              name="user[display_name]"
              value={Phoenix.HTML.Form.input_value(@changeset, :display_name)}
              placeholder="Your name"
              maxlength="50"
              class="w-full bg-sa-surface border border-sa-border rounded-lg px-4 py-2.5 text-sa-white font-['DM_Sans'] placeholder-sa-gray focus:border-sa-green focus:outline-none focus:ring-1 focus:ring-sa-green"
            />
            <.error :for={msg <- get_errors(@changeset, :display_name)}>{msg}</.error>
          </div>

          <div>
            <label class="block text-sm text-sa-gray-light font-['DM_Sans'] mb-1">Bio</label>
            <textarea
              name="user[bio]"
              rows="3"
              placeholder="Tell us about yourself"
              maxlength="160"
              class="w-full bg-sa-surface border border-sa-border rounded-lg px-4 py-2.5 text-sa-white font-['DM_Sans'] placeholder-sa-gray focus:border-sa-green focus:outline-none focus:ring-1 focus:ring-sa-green resize-none"
            >{Phoenix.HTML.Form.input_value(@changeset, :bio)}</textarea>
            <.error :for={msg <- get_errors(@changeset, :bio)}>{msg}</.error>
          </div>

          <div>
            <label class="block text-sm text-sa-gray-light font-['DM_Sans'] mb-1">Location</label>
            <input
              type="text"
              name="user[location]"
              value={Phoenix.HTML.Form.input_value(@changeset, :location)}
              placeholder="City, Country"
              maxlength="100"
              class="w-full bg-sa-surface border border-sa-border rounded-lg px-4 py-2.5 text-sa-white font-['DM_Sans'] placeholder-sa-gray focus:border-sa-green focus:outline-none focus:ring-1 focus:ring-sa-green"
            />
            <.error :for={msg <- get_errors(@changeset, :location)}>{msg}</.error>
          </div>

          <div class="flex gap-3 pt-2 rtl:flex-row-reverse">
            <button
              type="submit"
              class="px-6 py-2.5 rounded-full bg-sa-green text-sa-white font-['DM_Sans'] text-sm font-medium hover:bg-sa-green-light transition"
            >
              Save Changes
            </button>
            <.link
              navigate={~p"/u/#{@user.username}"}
              class="px-6 py-2.5 rounded-full border border-sa-border text-sa-white font-['DM_Sans'] text-sm hover:bg-sa-surface2 transition"
            >
              Cancel
            </.link>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  defp get_errors(changeset, field) do
    case changeset.action do
      nil ->
        []

      _ ->
        Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
          Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
            opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
          end)
        end)
        |> Map.get(field, [])
    end
  end
end
