defmodule BoilerworksWeb.AuthController do
  use BoilerworksWeb, :controller

  alias Boilerworks.Accounts
  alias BoilerworksWeb.Plugs.Auth

  def create(conn, %{"user" => %{"email" => email, "password" => password}}) do
    if user = Accounts.get_user_by_email_and_password(email, password) do
      Auth.log_in_user(conn, user)
    else
      conn
      |> put_flash(:error, "Invalid email or password")
      |> redirect(to: ~p"/login")
    end
  end

  def register(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        Auth.log_in_user(conn, user)

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Registration failed. Please check the form.")
        |> redirect(to: ~p"/register")
    end
  end

  def delete(conn, _params) do
    Auth.log_out_user(conn)
  end
end
