defmodule Boilerworks.Forms.FormSubmission do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "form_submissions" do
    field :data, :map
    field :status, :string, default: "draft"

    belongs_to :form_definition, Boilerworks.Forms.FormDefinition
    belongs_to :submitted_by, Boilerworks.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(submission, attrs) do
    submission
    |> cast(attrs, [:data, :status, :form_definition_id])
    |> validate_required([:data, :form_definition_id])
    |> validate_inclusion(:status, ["draft", "submitted", "approved", "rejected"])
  end
end
