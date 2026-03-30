defmodule BoilerworksWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint BoilerworksWeb.Endpoint

      use BoilerworksWeb, :verified_routes

      import Plug.Conn
      import Phoenix.ConnTest
      import BoilerworksWeb.ConnCase
    end
  end

  setup tags do
    Boilerworks.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  def register_and_log_in_user(%{conn: conn}) do
    user = user_fixture()
    setup_user_permissions(user)
    %{conn: log_in_user(conn, user), user: user}
  end

  def log_in_user(conn, user) do
    token = Boilerworks.Accounts.generate_user_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end

  def user_fixture(attrs \\ %{}) do
    unique = System.unique_integer([:positive])

    {:ok, user} =
      Boilerworks.Accounts.register_user(
        Map.merge(
          %{
            email: "user#{unique}@example.com",
            password: "password1234",
            first_name: "Test",
            last_name: "User"
          },
          attrs
        )
      )

    user
  end

  def user_without_permissions do
    user_fixture()
  end

  def setup_user_permissions(user) do
    alias Boilerworks.Repo
    alias Boilerworks.Accounts.{Group, Permission, UserGroup, GroupPermission}

    # Create admin group with all permissions
    {:ok, group} =
      %Group{}
      |> Group.changeset(%{
        name: "Test Admin #{System.unique_integer([:positive])}",
        slug: "test-admin-#{System.unique_integer([:positive])}"
      })
      |> Repo.insert()

    permission_slugs = ~w(
      item.view item.create item.edit item.delete
      category.view category.create category.edit category.delete
      form.view form.create form.edit form.delete form.submit
      workflow.view workflow.create workflow.edit workflow.delete workflow.transition
      user.manage
    )

    for slug <- permission_slugs do
      perm =
        case Repo.get_by(Permission, slug: slug) do
          nil ->
            {:ok, p} =
              %Permission{}
              |> Permission.changeset(%{name: slug, slug: slug})
              |> Repo.insert()

            p

          p ->
            p
        end

      Repo.insert!(%GroupPermission{group_id: group.id, permission_id: perm.id},
        on_conflict: :nothing,
        conflict_target: [:group_id, :permission_id]
      )
    end

    Repo.insert!(%UserGroup{user_id: user.id, group_id: group.id},
      on_conflict: :nothing,
      conflict_target: [:user_id, :group_id]
    )

    user
  end

  def setup_user_with_permissions(user, permission_slugs) do
    alias Boilerworks.Repo
    alias Boilerworks.Accounts.{Group, Permission, UserGroup, GroupPermission}

    {:ok, group} =
      %Group{}
      |> Group.changeset(%{
        name: "Limited #{System.unique_integer([:positive])}",
        slug: "limited-#{System.unique_integer([:positive])}"
      })
      |> Repo.insert()

    for slug <- permission_slugs do
      perm =
        case Repo.get_by(Permission, slug: slug) do
          nil ->
            {:ok, p} =
              %Permission{}
              |> Permission.changeset(%{name: slug, slug: slug})
              |> Repo.insert()

            p

          p ->
            p
        end

      Repo.insert!(%GroupPermission{group_id: group.id, permission_id: perm.id},
        on_conflict: :nothing,
        conflict_target: [:group_id, :permission_id]
      )
    end

    Repo.insert!(%UserGroup{user_id: user.id, group_id: group.id},
      on_conflict: :nothing,
      conflict_target: [:user_id, :group_id]
    )

    user
  end

  def register_and_log_in_viewer(%{conn: conn}) do
    user = user_fixture()
    setup_user_with_permissions(user, ~w(item.view category.view))
    %{conn: log_in_user(conn, user), user: user}
  end

  def item_fixture(attrs \\ %{}) do
    user = user_fixture()
    setup_user_permissions(user)

    {:ok, item} =
      Boilerworks.Catalog.create_item(
        Map.merge(
          %{"name" => "Test Item", "price" => "19.99"},
          attrs
        ),
        user
      )

    item
  end

  def category_fixture(attrs \\ %{}) do
    user = user_fixture()
    setup_user_permissions(user)

    {:ok, category} =
      Boilerworks.Catalog.create_category(
        Map.merge(%{"name" => "Test Category"}, attrs),
        user
      )

    category
  end
end
