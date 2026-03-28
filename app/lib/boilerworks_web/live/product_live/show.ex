defmodule BoilerworksWeb.ProductLive.Show do
  use BoilerworksWeb, :live_view

  alias Boilerworks.Catalog
  import BoilerworksWeb.Plugs.LiveAuth, only: [require_permission!: 2]

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    require_permission!(socket, "product.view")
    product = Catalog.get_product!(id)

    {:ok, assign(socket, product: product, page_title: product.name)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      <%= @product.name %>
      <:actions>
        <.link patch={~p"/products/#{@product}/edit"} phx-click={JS.push_focus()}>
          <.button>Edit</.button>
        </.link>
      </:actions>
    </.header>

    <div class="mt-8 space-y-6">
      <div class="grid grid-cols-2 gap-6">
        <div>
          <dt class="text-sm font-medium text-zinc-400">SKU</dt>
          <dd class="mt-1 text-sm text-zinc-200"><%= @product.sku || "-" %></dd>
        </div>
        <div>
          <dt class="text-sm font-medium text-zinc-400">Price</dt>
          <dd class="mt-1 text-sm text-zinc-200">$<%= @product.price %></dd>
        </div>
        <div>
          <dt class="text-sm font-medium text-zinc-400">Category</dt>
          <dd class="mt-1 text-sm text-zinc-200"><%= if @product.category, do: @product.category.name, else: "-" %></dd>
        </div>
        <div>
          <dt class="text-sm font-medium text-zinc-400">Slug</dt>
          <dd class="mt-1 text-sm text-zinc-200"><%= @product.slug %></dd>
        </div>
      </div>

      <div :if={@product.description}>
        <dt class="text-sm font-medium text-zinc-400">Description</dt>
        <dd class="mt-1 text-sm text-zinc-200"><%= @product.description %></dd>
      </div>
    </div>

    <.back navigate={~p"/products"}>Back to products</.back>
    """
  end
end
