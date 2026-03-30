defmodule Boilerworks.Forms.FormDefinition do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "form_definitions" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :schema, :map
    field :ui_schema, :map
    field :version, :integer, default: 1
    field :is_active, :boolean, default: true
    field :deleted_at, :utc_datetime

    belongs_to :created_by, Boilerworks.Accounts.User
    belongs_to :updated_by, Boilerworks.Accounts.User

    has_many :submissions, Boilerworks.Forms.FormSubmission

    timestamps(type: :utc_datetime)
  end

  def changeset(form_def, attrs) do
    form_def
    |> cast(attrs, [:name, :slug, :description, :schema, :ui_schema, :is_active])
    |> validate_required([:name, :schema])
    |> maybe_generate_slug()
    |> validate_json_schema()
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

  defp validate_json_schema(changeset) do
    case get_change(changeset, :schema) do
      nil ->
        changeset

      schema ->
        if is_map(schema) and Map.has_key?(schema, "fields") do
          changeset
        else
          add_error(changeset, :schema, "must be a valid form schema with 'fields' key")
        end
    end
  end
end
