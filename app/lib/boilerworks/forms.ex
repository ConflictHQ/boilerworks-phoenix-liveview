defmodule Boilerworks.Forms do
  @moduledoc """
  The Forms context. JSON schema-based dynamic form definitions and submissions.
  """

  import Ecto.Query
  alias Boilerworks.Repo
  alias Boilerworks.Forms.{FormDefinition, FormSubmission}

  ## Form Definitions

  def list_form_definitions do
    FormDefinition
    |> where([f], is_nil(f.deleted_at))
    |> order_by([f], desc: f.inserted_at)
    |> Repo.all()
  end

  def get_form_definition!(id) do
    FormDefinition
    |> where([f], is_nil(f.deleted_at))
    |> Repo.get!(id)
  end

  def create_form_definition(attrs, user) do
    %FormDefinition{}
    |> FormDefinition.changeset(attrs)
    |> Ecto.Changeset.put_change(:created_by_id, user.id)
    |> Ecto.Changeset.put_change(:updated_by_id, user.id)
    |> Repo.insert()
  end

  def update_form_definition(%FormDefinition{} = form_def, attrs, user) do
    form_def
    |> FormDefinition.changeset(attrs)
    |> Ecto.Changeset.put_change(:updated_by_id, user.id)
    |> Repo.update()
  end

  def delete_form_definition(%FormDefinition{} = form_def) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    form_def
    |> Ecto.Changeset.change(%{deleted_at: now})
    |> Repo.update()
  end

  def change_form_definition(%FormDefinition{} = form_def, attrs \\ %{}) do
    FormDefinition.changeset(form_def, attrs)
  end

  ## Submissions

  def list_submissions(form_definition_id) do
    FormSubmission
    |> where([s], s.form_definition_id == ^form_definition_id)
    |> order_by([s], desc: s.inserted_at)
    |> preload(:submitted_by)
    |> Repo.all()
  end

  def get_submission!(id) do
    FormSubmission
    |> preload([:form_definition, :submitted_by])
    |> Repo.get!(id)
  end

  def create_submission(attrs, user) do
    %FormSubmission{}
    |> FormSubmission.changeset(attrs)
    |> Ecto.Changeset.put_change(:submitted_by_id, user.id)
    |> Repo.insert()
  end

  def validate_submission_data(%FormDefinition{schema: schema}, data) do
    fields = Map.get(schema, "fields", [])

    errors =
      Enum.reduce(fields, [], fn field, acc ->
        field_name = Map.get(field, "name")
        required = Map.get(field, "required", false)
        value = Map.get(data, field_name)

        cond do
          required and (is_nil(value) or value == "") ->
            [{field_name, "is required"} | acc]

          true ->
            acc
        end
      end)

    case errors do
      [] -> :ok
      errors -> {:error, errors}
    end
  end

  def change_submission(%FormSubmission{} = submission, attrs \\ %{}) do
    FormSubmission.changeset(submission, attrs)
  end
end
