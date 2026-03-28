defmodule Boilerworks.Accounts.GroupPermission do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "group_permissions" do
    belongs_to :group, Boilerworks.Accounts.Group
    belongs_to :permission, Boilerworks.Accounts.Permission

    timestamps(type: :utc_datetime)
  end

  def changeset(group_permission, attrs) do
    group_permission
    |> cast(attrs, [:group_id, :permission_id])
    |> validate_required([:group_id, :permission_id])
    |> unique_constraint([:group_id, :permission_id])
  end
end
