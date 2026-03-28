defmodule Boilerworks.Authorization do
  @moduledoc """
  Group-based RBAC authorization. Permissions are always checked through groups,
  never assigned directly to users.
  """

  import Ecto.Query
  alias Boilerworks.Repo

  def has_permission?(%{id: user_id}, permission_slug) when is_binary(permission_slug) do
    Repo.exists?(
      from p in "permissions",
        join: gp in "group_permissions",
        on: gp.permission_id == p.id,
        join: ug in "user_groups",
        on: ug.group_id == gp.group_id,
        where: ug.user_id == type(^user_id, :binary_id) and p.slug == ^permission_slug
    )
  end

  def has_permission?(nil, _permission_slug), do: false

  def has_any_permission?(user, permission_slugs) when is_list(permission_slugs) do
    Enum.any?(permission_slugs, &has_permission?(user, &1))
  end

  def user_permissions(%{id: user_id}) do
    Repo.all(
      from p in "permissions",
        join: gp in "group_permissions",
        on: gp.permission_id == p.id,
        join: ug in "user_groups",
        on: ug.group_id == gp.group_id,
        where: ug.user_id == type(^user_id, :binary_id),
        select: p.slug,
        distinct: true
    )
  end

  def user_permissions(nil), do: []
end
