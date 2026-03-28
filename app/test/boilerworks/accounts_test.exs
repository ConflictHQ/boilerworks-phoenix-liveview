defmodule Boilerworks.AccountsTest do
  use Boilerworks.DataCase

  alias Boilerworks.Accounts
  alias Boilerworks.Accounts.User

  describe "register_user/1" do
    test "creates a user with valid attributes" do
      attrs = %{email: "test@example.com", password: "password1234"}
      assert {:ok, %User{} = user} = Accounts.register_user(attrs)
      assert user.email == "test@example.com"
      assert user.hashed_password != nil
      assert user.password == nil
    end

    test "rejects duplicate email" do
      attrs = %{email: "dup@example.com", password: "password1234"}
      {:ok, _} = Accounts.register_user(attrs)
      assert {:error, changeset} = Accounts.register_user(attrs)
      assert "has already been taken" in errors_on(changeset).email
    end

    test "rejects short password" do
      attrs = %{email: "test@example.com", password: "short"}
      assert {:error, changeset} = Accounts.register_user(attrs)
      assert errors_on(changeset).password != []
    end
  end

  describe "get_user_by_email_and_password/2" do
    test "returns user with valid credentials" do
      {:ok, user} = Accounts.register_user(%{email: "auth@example.com", password: "password1234"})
      found = Accounts.get_user_by_email_and_password("auth@example.com", "password1234")
      assert found.id == user.id
    end

    test "returns nil with invalid password" do
      Accounts.register_user(%{email: "auth2@example.com", password: "password1234"})
      refute Accounts.get_user_by_email_and_password("auth2@example.com", "wrongpassword")
    end
  end

  describe "session tokens" do
    test "generates and verifies session token" do
      {:ok, user} = Accounts.register_user(%{email: "session@example.com", password: "password1234"})
      token = Accounts.generate_user_session_token(user)
      assert is_binary(token)

      found = Accounts.get_user_by_session_token(token)
      assert found.id == user.id
    end

    test "deletes session token" do
      {:ok, user} = Accounts.register_user(%{email: "delete@example.com", password: "password1234"})
      token = Accounts.generate_user_session_token(user)
      Accounts.delete_user_session_token(token)
      refute Accounts.get_user_by_session_token(token)
    end
  end
end
