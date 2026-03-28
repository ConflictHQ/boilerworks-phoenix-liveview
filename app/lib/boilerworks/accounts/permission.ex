defmodule Boilerworks.Accounts.Permission do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "permissions" do
    field :name, :string
    field :slug, :string
    field :description, :string

    has_many :group_permissions, Boilerworks.Accounts.GroupPermission
    has_many :groups, through: [:group_permissions, :group]

    timestamps(type: :utc_datetime)
  end

  def changeset(permission, attrs) do
    permission
    |> cast(attrs, [:name, :slug, :description])
    |> validate_required([:name, :slug])
    |> unique_constraint(:slug)
  end
end
