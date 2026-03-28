defmodule BoilerworksWeb.AuthLive.Login do
  use BoilerworksWeb, :live_view

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form, page_title: "Log In"), layout: {BoilerworksWeb.Layouts, :root}}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-zinc-900">
      <div class="w-full max-w-md">
        <div class="bg-zinc-800 rounded-2xl border border-zinc-700 p-8">
          <h1 class="text-2xl font-bold text-emerald-400 text-center mb-2">Boilerworks</h1>
          <p class="text-zinc-400 text-center text-sm mb-8">Sign in to your account</p>

          <.form for={@form} action={~p"/login"} class="space-y-6">
            <.input field={@form[:email]} type="email" label="Email" required />
            <.input field={@form[:password]} type="password" label="Password" required />

            <div>
              <.button type="submit" class="w-full">
                Sign in
              </.button>
            </div>
          </.form>

          <p class="mt-6 text-center text-sm text-zinc-400">
            Don't have an account?
            <.link navigate={~p"/register"} class="text-emerald-400 hover:text-emerald-300 font-semibold">
              Register
            </.link>
          </p>
        </div>
      </div>
    </div>
    """
  end
end
