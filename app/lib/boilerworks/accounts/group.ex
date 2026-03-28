defmodule Boilerworks.Accounts.Group do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "groups" do
    field :name, :string
    field :slug, :string
    field :description, :string

    has_many :user_groups, Boilerworks.Accounts.UserGroup
    has_many :users, through: [:user_groups, :user]
    has_many :group_permissions, Boilerworks.Accounts.GroupPermission
    has_many :permissions, through: [:group_permissions, :permission]

    timestamps(type: :utc_datetime)
  end

  def changeset(group, attrs) do
    group
    |> cast(attrs, [:name, :slug, :description])
    |> validate_required([:name, :slug])
    |> unique_constraint(:slug)
  end
end
