defmodule Boilerworks.Catalog.Item do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "items" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :price, :decimal
    field :sku, :string
    field :deleted_at, :utc_datetime

    belongs_to :category, Boilerworks.Catalog.Category
    belongs_to :created_by, Boilerworks.Accounts.User
    belongs_to :updated_by, Boilerworks.Accounts.User
    belongs_to :deleted_by, Boilerworks.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:name, :slug, :description, :price, :sku, :category_id])
    |> validate_required([:name, :price])
    |> validate_number(:price, greater_than: 0)
    |> maybe_generate_slug()
    |> unique_constraint(:slug)
    |> unique_constraint(:sku)
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
