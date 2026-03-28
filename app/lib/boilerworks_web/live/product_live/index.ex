defmodule BoilerworksWeb.ProductLive.Index do
  use BoilerworksWeb, :live_view

  alias Boilerworks.Catalog
  alias Boilerworks.Catalog.Product
  import BoilerworksWeb.Plugs.LiveAuth, only: [require_permission!: 2]

  @impl true
  def mount(_params, _session, socket) do
    require_permission!(socket, "product.view")

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Boilerworks.PubSub, "products")
    end

    {:ok, assign(socket, products: Catalog.list_products(), search: "")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, page_title: "Products", product: nil)
  end

  defp apply_action(socket, :new, _params) do
    assign(socket, page_title: "New Product", product: %Product{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    assign(socket, page_title: "Edit Product", product: Catalog.get_product!(id))
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    products = Catalog.list_products(search: search)
    {:noreply, assign(socket, products: products, search: search)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    require_permission!(socket, "product.delete")
    product = Catalog.get_product!(id)
    {:ok, _} = Catalog.delete_product(product, socket.assigns.current_user)
    {:noreply, assign(socket, products: Catalog.list_products(search: socket.assigns.search))}
  end

  @impl true
  def handle_info({:product_created, _product}, socket) do
    {:noreply, assign(socket, products: Catalog.list_products(search: socket.assigns.search))}
  end

  @impl true
  def handle_info({:product_updated, _product}, socket) do
    {:noreply, assign(socket, products: Catalog.list_products(search: socket.assigns.search))}
  end

  @impl true
  def handle_info({:product_deleted, _product}, socket) do
    {:noreply, assign(socket, products: Catalog.list_products(search: socket.assigns.search))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Products
      <:actions>
        <.link patch={~p"/products/new"}>
          <.button>New Product</.button>
        </.link>
      </:actions>
    </.header>

    <div class="mt-6">
      <form phx-change="search" class="mb-6">
        <input
          type="text"
          name="search"
          value={@search}
          placeholder="Search products..."
          phx-debounce="300"
          class="w-full rounded-lg border-zinc-600 bg-zinc-700 text-zinc-200 focus:ring-0 sm:text-sm"
        />
      </form>

      <.table id="products" rows={@products}>
        <:col :let={product} label="Name"><%= product.name %></:col>
        <:col :let={product} label="SKU"><%= product.sku %></:col>
        <:col :let={product} label="Price">$<%= product.price %></:col>
        <:col :let={product} label="Category"><%= if product.category, do: product.category.name, else: "-" %></:col>
        <:action :let={product}>
          <.link patch={~p"/products/#{product}/edit"}>Edit</.link>
        </:action>
        <:action :let={product}>
          <.link phx-click={JS.push("delete", value: %{id: product.id})} data-confirm="Are you sure?">
            Delete
          </.link>
        </:action>
      </.table>
    </div>

    <.modal :if={@live_action in [:new, :edit]} id="product-modal" show on_cancel={JS.patch(~p"/products")}>
      <.live_component
        module={BoilerworksWeb.ProductLive.FormComponent}
        id={@product.id || :new}
        title={@page_title}
        action={@live_action}
        product={@product}
        current_user={@current_user}
        patch={~p"/products"}
      />
    </.modal>
    """
  end
end
