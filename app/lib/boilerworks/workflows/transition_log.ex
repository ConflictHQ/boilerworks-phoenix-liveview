defmodule Boilerworks.Workflows.TransitionLog do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "workflow_transition_logs" do
    field :from_state, :string
    field :to_state, :string
    field :transition_name, :string
    field :metadata, :map, default: %{}

    belongs_to :workflow_instance, Boilerworks.Workflows.WorkflowInstance
    belongs_to :performed_by, Boilerworks.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(log, attrs) do
    log
    |> cast(attrs, [
      :from_state,
      :to_state,
      :transition_name,
      :metadata,
      :workflow_instance_id,
      :performed_by_id
    ])
    |> validate_required([:from_state, :to_state, :transition_name, :workflow_instance_id])
  end
end
