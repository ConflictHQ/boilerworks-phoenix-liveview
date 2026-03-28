defmodule Boilerworks.Repo.Migrations.CreateGroupsAndPermissions do
  use Ecto.Migration

  def change do
    create table(:groups, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:groups, [:slug])

    create table(:permissions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:permissions, [:slug])

    create table(:user_groups, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :group_id, references(:groups, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_groups, [:user_id, :group_id])
    create index(:user_groups, [:group_id])

    create table(:group_permissions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :group_id, references(:groups, type: :binary_id, on_delete: :delete_all), null: false
      add :permission_id, references(:permissions, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:group_permissions, [:group_id, :permission_id])
    create index(:group_permissions, [:permission_id])
  end
end
