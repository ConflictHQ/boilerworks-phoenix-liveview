defmodule BoilerworksWeb.ItemLive.Show do
  use BoilerworksWeb, :live_view

  alias Boilerworks.Catalog
  import BoilerworksWeb.Plugs.LiveAuth, only: [require_permission!: 2]

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    require_permission!(socket, "item.view")
    item = Catalog.get_item!(id)

    {:ok, assign(socket, item: item, page_title: item.name)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      {@item.name}
      <:actions>
        <.link patch={~p"/items/#{@item}/edit"} phx-click={JS.push_focus()}>
          <.button>Edit</.button>
        </.link>
      </:actions>
    </.header>

    <div class="mt-8 space-y-6">
      <div class="grid grid-cols-2 gap-6">
        <div>
          <dt class="text-sm font-medium text-zinc-400">SKU</dt>
          <dd class="mt-1 text-sm text-zinc-200">{@item.sku || "-"}</dd>
        </div>
        <div>
          <dt class="text-sm font-medium text-zinc-400">Price</dt>
          <dd class="mt-1 text-sm text-zinc-200">${@item.price}</dd>
        </div>
        <div>
          <dt class="text-sm font-medium text-zinc-400">Category</dt>
          <dd class="mt-1 text-sm text-zinc-200">
            {if @item.category, do: @item.category.name, else: "-"}
          </dd>
        </div>
        <div>
          <dt class="text-sm font-medium text-zinc-400">Slug</dt>
          <dd class="mt-1 text-sm text-zinc-200">{@item.slug}</dd>
        </div>
      </div>

      <div :if={@item.description}>
        <dt class="text-sm font-medium text-zinc-400">Description</dt>
        <dd class="mt-1 text-sm text-zinc-200">{@item.description}</dd>
      </div>
    </div>

    <.back navigate={~p"/items"}>Back to items</.back>
    """
  end
end
