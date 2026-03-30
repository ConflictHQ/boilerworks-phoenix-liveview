defmodule BoilerworksWeb.ItemLive.Index do
  use BoilerworksWeb, :live_view

  alias Boilerworks.Catalog
  alias Boilerworks.Catalog.Item
  import BoilerworksWeb.Plugs.LiveAuth, only: [require_permission!: 2]

  @impl true
  def mount(_params, _session, socket) do
    require_permission!(socket, "item.view")

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Boilerworks.PubSub, "items")
    end

    {:ok, assign(socket, items: Catalog.list_items(), search: "")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, page_title: "Items", item: nil)
  end

  defp apply_action(socket, :new, _params) do
    assign(socket, page_title: "New Item", item: %Item{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    assign(socket, page_title: "Edit Item", item: Catalog.get_item!(id))
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    items = Catalog.list_items(search: search)
    {:noreply, assign(socket, items: items, search: search)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    require_permission!(socket, "item.delete")
    item = Catalog.get_item!(id)
    {:ok, _} = Catalog.delete_item(item, socket.assigns.current_user)
    {:noreply, assign(socket, items: Catalog.list_items(search: socket.assigns.search))}
  end

  @impl true
  def handle_info({:item_created, _item}, socket) do
    {:noreply, assign(socket, items: Catalog.list_items(search: socket.assigns.search))}
  end

  @impl true
  def handle_info({:item_updated, _item}, socket) do
    {:noreply, assign(socket, items: Catalog.list_items(search: socket.assigns.search))}
  end

  @impl true
  def handle_info({:item_deleted, _item}, socket) do
    {:noreply, assign(socket, items: Catalog.list_items(search: socket.assigns.search))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Items
      <:actions>
        <.link patch={~p"/items/new"}>
          <.button>New Item</.button>
        </.link>
      </:actions>
    </.header>

    <div class="mt-6">
      <form phx-change="search" class="mb-6">
        <input
          type="text"
          name="search"
          value={@search}
          placeholder="Search items..."
          phx-debounce="300"
          class="w-full rounded-lg border-zinc-600 bg-zinc-700 text-zinc-200 focus:ring-0 sm:text-sm"
        />
      </form>

      <.table id="items" rows={@items}>
        <:col :let={item} label="Name">{item.name}</:col>
        <:col :let={item} label="SKU">{item.sku}</:col>
        <:col :let={item} label="Price">${item.price}</:col>
        <:col :let={item} label="Category">
          {if item.category, do: item.category.name, else: "-"}
        </:col>
        <:action :let={item}>
          <.link patch={~p"/items/#{item}/edit"}>Edit</.link>
        </:action>
        <:action :let={item}>
          <.link phx-click={JS.push("delete", value: %{id: item.id})} data-confirm="Are you sure?">
            Delete
          </.link>
        </:action>
      </.table>
    </div>

    <.modal :if={@live_action in [:new, :edit]} id="item-modal" show on_cancel={JS.patch(~p"/items")}>
      <.live_component
        module={BoilerworksWeb.ItemLive.FormComponent}
        id={@item.id || :new}
        title={@page_title}
        action={@live_action}
        item={@item}
        current_user={@current_user}
        patch={~p"/items"}
      />
    </.modal>
    """
  end
end
