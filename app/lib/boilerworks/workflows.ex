defmodule Boilerworks.Workflows do
  @moduledoc """
  The Workflows context. State machine engine with transition logging and real-time updates.
  """

  import Ecto.Query
  alias Boilerworks.Repo
  alias Boilerworks.Workflows.{WorkflowDefinition, WorkflowInstance, TransitionLog}

  ## Workflow Definitions

  def list_workflow_definitions do
    WorkflowDefinition
    |> where([w], is_nil(w.deleted_at))
    |> order_by([w], desc: w.inserted_at)
    |> Repo.all()
  end

  def get_workflow_definition!(id) do
    WorkflowDefinition
    |> where([w], is_nil(w.deleted_at))
    |> Repo.get!(id)
  end

  def create_workflow_definition(attrs, user) do
    %WorkflowDefinition{}
    |> WorkflowDefinition.changeset(attrs)
    |> Ecto.Changeset.put_change(:created_by_id, user.id)
    |> Ecto.Changeset.put_change(:updated_by_id, user.id)
    |> Repo.insert()
  end

  def update_workflow_definition(%WorkflowDefinition{} = workflow_def, attrs, user) do
    workflow_def
    |> WorkflowDefinition.changeset(attrs)
    |> Ecto.Changeset.put_change(:updated_by_id, user.id)
    |> Repo.update()
  end

  def delete_workflow_definition(%WorkflowDefinition{} = workflow_def) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    workflow_def
    |> Ecto.Changeset.change(%{deleted_at: now})
    |> Repo.update()
  end

  def change_workflow_definition(%WorkflowDefinition{} = workflow_def, attrs \\ %{}) do
    WorkflowDefinition.changeset(workflow_def, attrs)
  end

  ## Workflow Instances

  def list_instances(workflow_definition_id) do
    WorkflowInstance
    |> where([i], i.workflow_definition_id == ^workflow_definition_id)
    |> order_by([i], desc: i.inserted_at)
    |> preload(:created_by)
    |> Repo.all()
  end

  def get_instance!(id) do
    WorkflowInstance
    |> preload([:workflow_definition, :created_by, transition_logs: :performed_by])
    |> Repo.get!(id)
  end

  def create_instance(%WorkflowDefinition{} = workflow_def, attrs, user) do
    %WorkflowInstance{}
    |> WorkflowInstance.changeset(Map.merge(attrs, %{
      "current_state" => workflow_def.initial_state,
      "workflow_definition_id" => workflow_def.id
    }))
    |> Ecto.Changeset.put_change(:created_by_id, user.id)
    |> Repo.insert()
    |> case do
      {:ok, instance} ->
        broadcast_workflow_change(workflow_def.id, {:instance_created, instance})
        {:ok, instance}

      error ->
        error
    end
  end

  def transition(%WorkflowInstance{} = instance, transition_name, user) do
    workflow_def = get_workflow_definition!(instance.workflow_definition_id)
    transitions = workflow_def.transitions || []

    transition =
      Enum.find(transitions, fn t ->
        t["name"] == transition_name and
          t["from"] == instance.current_state
      end)

    case transition do
      nil ->
        {:error, :invalid_transition}

      %{"to" => to_state} ->
        Ecto.Multi.new()
        |> Ecto.Multi.update(:instance,
          WorkflowInstance.changeset(instance, %{"current_state" => to_state})
          |> maybe_mark_completed(to_state, workflow_def)
        )
        |> Ecto.Multi.insert(:log, %TransitionLog{
          from_state: instance.current_state,
          to_state: to_state,
          transition_name: transition_name,
          workflow_instance_id: instance.id,
          performed_by_id: user.id
        })
        |> Repo.transaction()
        |> case do
          {:ok, %{instance: updated_instance}} ->
            broadcast_workflow_change(
              instance.workflow_definition_id,
              {:instance_transitioned, updated_instance}
            )

            {:ok, updated_instance}

          {:error, _op, changeset, _changes} ->
            {:error, changeset}
        end
    end
  end

  def available_transitions(%WorkflowInstance{} = instance) do
    workflow_def = get_workflow_definition!(instance.workflow_definition_id)
    transitions = workflow_def.transitions || []

    Enum.filter(transitions, fn t -> t["from"] == instance.current_state end)
  end

  ## Helpers

  defp maybe_mark_completed(changeset, to_state, workflow_def) do
    states = workflow_def.states || %{}
    state_config = Map.get(states, to_state, %{})

    if Map.get(state_config, "terminal", false) do
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      Ecto.Changeset.put_change(changeset, :completed_at, now)
    else
      changeset
    end
  end

  defp broadcast_workflow_change(workflow_def_id, message) do
    Phoenix.PubSub.broadcast(Boilerworks.PubSub, "workflow:#{workflow_def_id}", message)
  end
end
