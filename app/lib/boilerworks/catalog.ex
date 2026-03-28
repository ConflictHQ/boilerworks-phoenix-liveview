defmodule Boilerworks.Catalog do
  @moduledoc """
  The Catalog context. Products and categories with soft deletes and audit trails.
  """

  import Ecto.Query
  alias Boilerworks.Repo
  alias Boilerworks.Catalog.{Product, Category}

  ## Products

  def list_products(opts \\ []) do
    search = Keyword.get(opts, :search, "")
    category_id = Keyword.get(opts, :category_id)

    Product
    |> where([p], is_nil(p.deleted_at))
    |> maybe_filter_by_category(category_id)
    |> maybe_search(search)
    |> order_by([p], desc: p.inserted_at)
    |> preload(:category)
    |> Repo.all()
  end

  def get_product!(id) do
    Product
    |> where([p], is_nil(p.deleted_at))
    |> preload(:category)
    |> Repo.get!(id)
  end

  def get_product_by_slug(slug) do
    Product
    |> where([p], is_nil(p.deleted_at) and p.slug == ^slug)
    |> preload(:category)
    |> Repo.one()
  end

  def create_product(attrs, user) do
    %Product{}
    |> Product.changeset(attrs)
    |> Ecto.Changeset.put_change(:created_by_id, user.id)
    |> Ecto.Changeset.put_change(:updated_by_id, user.id)
    |> Repo.insert()
    |> tap_ok(&broadcast_product_change({:product_created, &1}))
  end

  def update_product(%Product{} = product, attrs, user) do
    product
    |> Product.changeset(attrs)
    |> Ecto.Changeset.put_change(:updated_by_id, user.id)
    |> Repo.update()
    |> tap_ok(&broadcast_product_change({:product_updated, &1}))
  end

  def delete_product(%Product{} = product, user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    product
    |> Ecto.Changeset.change(%{deleted_at: now, deleted_by_id: user.id})
    |> Repo.update()
    |> tap_ok(&broadcast_product_change({:product_deleted, &1}))
  end

  def change_product(%Product{} = product, attrs \\ %{}) do
    Product.changeset(product, attrs)
  end

  ## Categories

  def list_categories(opts \\ []) do
    search = Keyword.get(opts, :search, "")

    Category
    |> where([c], is_nil(c.deleted_at))
    |> maybe_search(search)
    |> order_by([c], asc: c.name)
    |> Repo.all()
  end

  def get_category!(id) do
    Category
    |> where([c], is_nil(c.deleted_at))
    |> Repo.get!(id)
  end

  def create_category(attrs, user) do
    %Category{}
    |> Category.changeset(attrs)
    |> Ecto.Changeset.put_change(:created_by_id, user.id)
    |> Ecto.Changeset.put_change(:updated_by_id, user.id)
    |> Repo.insert()
  end

  def update_category(%Category{} = category, attrs, user) do
    category
    |> Category.changeset(attrs)
    |> Ecto.Changeset.put_change(:updated_by_id, user.id)
    |> Repo.update()
  end

  def delete_category(%Category{} = category, user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    category
    |> Ecto.Changeset.change(%{deleted_at: now, deleted_by_id: user.id})
    |> Repo.update()
  end

  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end

  ## Helpers

  defp maybe_filter_by_category(query, nil), do: query

  defp maybe_filter_by_category(query, category_id) do
    where(query, [p], p.category_id == ^category_id)
  end

  defp maybe_search(query, ""), do: query
  defp maybe_search(query, nil), do: query

  defp maybe_search(query, search) do
    search_term = "%#{search}%"
    where(query, [q], ilike(q.name, ^search_term))
  end

  defp broadcast_product_change(message) do
    Phoenix.PubSub.broadcast(Boilerworks.PubSub, "products", message)
  end

  defp tap_ok({:ok, record}, fun) do
    fun.(record)
    {:ok, record}
  end

  defp tap_ok(error, _fun), do: error
end
