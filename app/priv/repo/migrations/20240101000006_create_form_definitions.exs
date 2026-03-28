defmodule Boilerworks.Repo.Migrations.CreateFormDefinitions do
  use Ecto.Migration

  def change do
    create table(:form_definitions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :schema, :map, null: false
      add :ui_schema, :map
      add :version, :integer, default: 1
      add :is_active, :boolean, default: true
      add :deleted_at, :utc_datetime
      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:form_definitions, [:slug])

    create table(:form_submissions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :data, :map, null: false
      add :status, :string, default: "draft"
      add :form_definition_id, references(:form_definitions, type: :binary_id, on_delete: :restrict), null: false
      add :submitted_by_id, references(:users, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:form_submissions, [:form_definition_id])
    create index(:form_submissions, [:submitted_by_id])
  end
end
