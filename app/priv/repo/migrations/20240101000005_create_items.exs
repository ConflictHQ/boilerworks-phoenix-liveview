defmodule Boilerworks.Repo.Migrations.CreateItems do
  use Ecto.Migration

  def change do
    create table(:items, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :price, :decimal, null: false
      add :sku, :string
      add :deleted_at, :utc_datetime
      add :category_id, references(:categories, type: :binary_id)
      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)
      add :deleted_by_id, references(:users, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:items, [:slug])
    create unique_index(:items, [:sku])
    create index(:items, [:category_id])
  end
end
