defmodule BoilerworksWeb.AuthLive.Register do
  use BoilerworksWeb, :live_view

  alias Boilerworks.Accounts
  alias Boilerworks.Accounts.User

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})
    {:ok, assign(socket, form: to_form(changeset, as: "user"), page_title: "Register"), layout: {BoilerworksWeb.Layouts, :root}}
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      %User{}
      |> Accounts.change_user_registration(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, as: "user"))}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-zinc-900">
      <div class="w-full max-w-md">
        <div class="bg-zinc-800 rounded-2xl border border-zinc-700 p-8">
          <h1 class="text-2xl font-bold text-emerald-400 text-center mb-2">Boilerworks</h1>
          <p class="text-zinc-400 text-center text-sm mb-8">Create your account</p>

          <.form for={@form} action={~p"/register"} phx-change="validate" class="space-y-6">
            <.input field={@form[:first_name]} type="text" label="First Name" />
            <.input field={@form[:last_name]} type="text" label="Last Name" />
            <.input field={@form[:email]} type="email" label="Email" required />
            <.input field={@form[:password]} type="password" label="Password" required />

            <div>
              <.button type="submit" class="w-full">
                Create account
              </.button>
            </div>
          </.form>

          <p class="mt-6 text-center text-sm text-zinc-400">
            Already have an account?
            <.link navigate={~p"/login"} class="text-emerald-400 hover:text-emerald-300 font-semibold">
              Sign in
            </.link>
          </p>
        </div>
      </div>
    </div>
    """
  end
end
