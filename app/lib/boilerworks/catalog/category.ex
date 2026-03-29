defmodule Boilerworks.Catalog.Category do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "categories" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :deleted_at, :utc_datetime
    belongs_to :deleted_by, Boilerworks.Accounts.User
    belongs_to :created_by, Boilerworks.Accounts.User
    belongs_to :updated_by, Boilerworks.Accounts.User

    has_many :items, Boilerworks.Catalog.Item

    timestamps(type: :utc_datetime)
  end

  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :slug, :description])
    |> validate_required([:name])
    |> maybe_generate_slug()
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
end
