defmodule Boilerworks.Accounts do
  @moduledoc """
  The Accounts context. Handles user registration, authentication, and session management.
  """

  import Ecto.Query
  alias Boilerworks.Repo
  alias Boilerworks.Accounts.{User, UserToken}

  ## User queries

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = get_user_by_email(email)
    if User.valid_password?(user, password), do: user
  end

  def get_user!(id), do: Repo.get!(User, id)

  ## Registration

  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## Session

  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  def get_user_by_session_token(token) do
    token
    |> UserToken.verify_session_token_query()
    |> Repo.one()
  end

  def delete_user_session_token(token) do
    token
    |> UserToken.by_token_and_context_query("session")
    |> Repo.delete_all()

    :ok
  end

  ## Password

  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  ## User listing (admin)

  def list_users do
    Repo.all(from u in User, order_by: [desc: u.inserted_at])
  end
end
