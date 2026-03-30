defmodule Boilerworks.Workflows.WorkflowDefinition do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "workflow_definitions" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :states, :map
    field :transitions, {:array, :map}
    field :initial_state, :string
    field :is_active, :boolean, default: true
    field :deleted_at, :utc_datetime

    belongs_to :created_by, Boilerworks.Accounts.User
    belongs_to :updated_by, Boilerworks.Accounts.User

    has_many :instances, Boilerworks.Workflows.WorkflowInstance

    timestamps(type: :utc_datetime)
  end

  def changeset(workflow_def, attrs) do
    workflow_def
    |> cast(attrs, [:name, :slug, :description, :states, :transitions, :initial_state, :is_active])
    |> validate_required([:name, :states, :transitions, :initial_state])
    |> maybe_generate_slug()
    |> validate_states_and_transitions()
    |> unique_constraint(:slug)
  end

  defp maybe_generate_slug(changeset) do
    case get_change(changeset, :slug) do
      nil ->
        case get_change(changeset, :name) do
          nil ->
            changeset

          name ->
            slug =
              name
              |> String.downcase()
              |> String.replace(~r/[^a-z0-9\s-]/, "")
              |> String.replace(~r/\s+/, "-")
              |> String.trim("-")

            put_change(changeset, :slug, slug)
        end

      _ ->
        changeset
    end
  end

  defp validate_states_and_transitions(changeset) do
    states = get_change(changeset, :states) || get_field(changeset, :states)
    initial = get_change(changeset, :initial_state) || get_field(changeset, :initial_state)

    cond do
      is_nil(states) ->
        changeset

      is_nil(initial) ->
        changeset

      not is_map(states) ->
        add_error(changeset, :states, "must be a map of state names to config")

      not Map.has_key?(states, initial) ->
        add_error(changeset, :initial_state, "must be a valid state")

      true ->
        changeset
    end
  end
end
