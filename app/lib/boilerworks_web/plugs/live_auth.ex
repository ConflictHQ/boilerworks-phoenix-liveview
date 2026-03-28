defmodule BoilerworksWeb.Plugs.LiveAuth do
  @moduledoc """
  LiveView on_mount hooks for authentication and authorization.
  """

  import Phoenix.LiveView
  import Phoenix.Component

  alias Boilerworks.Accounts
  alias Boilerworks.Authorization

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/login")}
    end
  end

  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, mount_current_user(socket, session)}
  end

  def on_mount(:redirect_if_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:halt, redirect(socket, to: "/")}
    else
      {:cont, socket}
    end
  end

  defp mount_current_user(socket, session) do
    assign_new(socket, :current_user, fn ->
      if user_token = session["user_token"] do
        Accounts.get_user_by_session_token(user_token)
      end
    end)
  end

  def require_permission!(socket, permission_slug) do
    unless Authorization.has_permission?(socket.assigns.current_user, permission_slug) do
      raise BoilerworksWeb.ForbiddenError, message: "Forbidden"
    end
  end
end
