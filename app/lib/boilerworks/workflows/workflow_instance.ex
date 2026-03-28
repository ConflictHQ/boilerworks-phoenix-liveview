defmodule Boilerworks.Workflows.WorkflowInstance do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "workflow_instances" do
    field :current_state, :string
    field :data, :map, default: %{}
    field :entity_type, :string
    field :entity_id, :binary_id
    field :completed_at, :utc_datetime

    belongs_to :workflow_definition, Boilerworks.Workflows.WorkflowDefinition
    belongs_to :created_by, Boilerworks.Accounts.User

    has_many :transition_logs, Boilerworks.Workflows.TransitionLog

    timestamps(type: :utc_datetime)
  end

  def changeset(instance, attrs) do
    instance
    |> cast(attrs, [:current_state, :data, :entity_type, :entity_id, :workflow_definition_id, :completed_at])
    |> validate_required([:current_state, :workflow_definition_id])
  end
end
