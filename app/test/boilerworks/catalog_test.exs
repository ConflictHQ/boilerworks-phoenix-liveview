defmodule Boilerworks.CatalogTest do
  use Boilerworks.DataCase

  alias Boilerworks.Catalog
  alias Boilerworks.Catalog

  def user_fixture do
    {:ok, user} =
      Boilerworks.Accounts.register_user(%{
        email: "catalog-#{System.unique_integer([:positive])}@example.com",
        password: "password1234"
      })

    user
  end

  describe "products" do
    test "list_products/0 returns non-deleted products" do
      user = user_fixture()
      {:ok, product} = Catalog.create_product(%{"name" => "Widget", "price" => "9.99"}, user)
      products = Catalog.list_products()
      assert Enum.any?(products, fn p -> p.id == product.id end)
    end

    test "list_products/1 filters by search" do
      user = user_fixture()
      {:ok, _p1} = Catalog.create_product(%{"name" => "Alpha Widget", "price" => "9.99"}, user)
      {:ok, _p2} = Catalog.create_product(%{"name" => "Beta Gadget", "price" => "19.99"}, user)

      results = Catalog.list_products(search: "Alpha")
      assert length(results) == 1
      assert hd(results).name == "Alpha Widget"
    end

    test "create_product/2 sets audit fields" do
      user = user_fixture()
      {:ok, product} = Catalog.create_product(%{"name" => "Audited", "price" => "5.00"}, user)
      assert product.created_by_id == user.id
      assert product.updated_by_id == user.id
    end

    test "create_product/2 generates slug" do
      user = user_fixture()
      {:ok, product} = Catalog.create_product(%{"name" => "My New Product", "price" => "5.00"}, user)
      assert product.slug == "my-new-product"
    end

    test "create_product/2 rejects missing price" do
      user = user_fixture()
      assert {:error, changeset} = Catalog.create_product(%{"name" => "No Price"}, user)
      assert errors_on(changeset).price != []
    end

    test "create_product/2 rejects zero price" do
      user = user_fixture()
      assert {:error, changeset} = Catalog.create_product(%{"name" => "Free", "price" => "0"}, user)
      assert errors_on(changeset).price != []
    end

    test "update_product/3 updates the product" do
      user = user_fixture()
      {:ok, product} = Catalog.create_product(%{"name" => "Original", "price" => "10.00"}, user)
      {:ok, updated} = Catalog.update_product(product, %{"name" => "Updated"}, user)
      assert updated.name == "Updated"
    end

    test "delete_product/2 soft deletes" do
      user = user_fixture()
      {:ok, product} = Catalog.create_product(%{"name" => "To Delete", "price" => "10.00"}, user)
      {:ok, deleted} = Catalog.delete_product(product, user)
      assert deleted.deleted_at != nil
      assert deleted.deleted_by_id == user.id

      # Should not appear in list
      products = Catalog.list_products()
      refute Enum.any?(products, fn p -> p.id == product.id end)
    end
  end

  describe "categories" do
    test "list_categories/0 returns non-deleted categories" do
      user = user_fixture()
      {:ok, category} = Catalog.create_category(%{"name" => "Test Cat"}, user)
      categories = Catalog.list_categories()
      assert Enum.any?(categories, fn c -> c.id == category.id end)
    end

    test "create_category/2 generates slug" do
      user = user_fixture()
      {:ok, category} = Catalog.create_category(%{"name" => "My Category"}, user)
      assert category.slug == "my-category"
    end

    test "delete_category/2 soft deletes" do
      user = user_fixture()
      {:ok, category} = Catalog.create_category(%{"name" => "To Delete Cat"}, user)
      {:ok, deleted} = Catalog.delete_category(category, user)
      assert deleted.deleted_at != nil
    end
  end
end
