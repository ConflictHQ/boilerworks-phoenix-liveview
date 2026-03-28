defmodule Boilerworks.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    create table(:categories, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :deleted_at, :utc_datetime
      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)
      add :deleted_by_id, references(:users, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:categories, [:slug])
  end
end
