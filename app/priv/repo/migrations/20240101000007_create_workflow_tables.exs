defmodule Boilerworks.Repo.Migrations.CreateWorkflowTables do
  use Ecto.Migration

  def change do
    create table(:workflow_definitions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :states, :map, null: false
      add :transitions, {:array, :map}, null: false
      add :initial_state, :string, null: false
      add :is_active, :boolean, default: true
      add :deleted_at, :utc_datetime
      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:workflow_definitions, [:slug])

    create table(:workflow_instances, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :current_state, :string, null: false
      add :data, :map, default: %{}
      add :entity_type, :string
      add :entity_id, :binary_id
      add :completed_at, :utc_datetime
      add :workflow_definition_id, references(:workflow_definitions, type: :binary_id, on_delete: :restrict), null: false
      add :created_by_id, references(:users, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:workflow_instances, [:workflow_definition_id])
    create index(:workflow_instances, [:entity_type, :entity_id])

    create table(:workflow_transition_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :from_state, :string, null: false
      add :to_state, :string, null: false
      add :transition_name, :string, null: false
      add :metadata, :map, default: %{}
      add :workflow_instance_id, references(:workflow_instances, type: :binary_id, on_delete: :delete_all), null: false
      add :performed_by_id, references(:users, type: :binary_id)

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:workflow_transition_logs, [:workflow_instance_id])
  end
end
