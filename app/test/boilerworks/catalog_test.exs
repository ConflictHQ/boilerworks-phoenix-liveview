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

  describe "items" do
    test "list_items/0 returns non-deleted items" do
      user = user_fixture()
      {:ok, item} = Catalog.create_item(%{"name" => "Widget", "price" => "9.99"}, user)
      items = Catalog.list_items()
      assert Enum.any?(items, fn p -> p.id == item.id end)
    end

    test "list_items/1 filters by search" do
      user = user_fixture()
      {:ok, _p1} = Catalog.create_item(%{"name" => "Alpha Widget", "price" => "9.99"}, user)
      {:ok, _p2} = Catalog.create_item(%{"name" => "Beta Gadget", "price" => "19.99"}, user)

      results = Catalog.list_items(search: "Alpha")
      assert length(results) == 1
      assert hd(results).name == "Alpha Widget"
    end

    test "create_item/2 sets audit fields" do
      user = user_fixture()
      {:ok, item} = Catalog.create_item(%{"name" => "Audited", "price" => "5.00"}, user)
      assert item.created_by_id == user.id
      assert item.updated_by_id == user.id
    end

    test "create_item/2 generates slug" do
      user = user_fixture()
      {:ok, item} = Catalog.create_item(%{"name" => "My New Item", "price" => "5.00"}, user)
      assert item.slug == "my-new-item"
    end

    test "create_item/2 rejects missing price" do
      user = user_fixture()
      assert {:error, changeset} = Catalog.create_item(%{"name" => "No Price"}, user)
      assert errors_on(changeset).price != []
    end

    test "create_item/2 rejects zero price" do
      user = user_fixture()
      assert {:error, changeset} = Catalog.create_item(%{"name" => "Free", "price" => "0"}, user)
      assert errors_on(changeset).price != []
    end

    test "update_item/3 updates the item" do
      user = user_fixture()
      {:ok, item} = Catalog.create_item(%{"name" => "Original", "price" => "10.00"}, user)
      {:ok, updated} = Catalog.update_item(item, %{"name" => "Updated"}, user)
      assert updated.name == "Updated"
    end

    test "delete_item/2 soft deletes" do
      user = user_fixture()
      {:ok, item} = Catalog.create_item(%{"name" => "To Delete", "price" => "10.00"}, user)
      {:ok, deleted} = Catalog.delete_item(item, user)
      assert deleted.deleted_at != nil
      assert deleted.deleted_by_id == user.id

      # Should not appear in list
      items = Catalog.list_items()
      refute Enum.any?(items, fn p -> p.id == item.id end)
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
