defmodule BoilerworksWeb.ItemLive.FormComponent do
  use BoilerworksWeb, :live_component

  alias Boilerworks.Catalog

  @impl true
  def update(%{item: item} = assigns, socket) do
    categories = Catalog.list_categories()
    changeset = Catalog.change_item(item)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(categories: categories)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"item" => item_params}, socket) do
    changeset =
      socket.assigns.item
      |> Catalog.change_item(item_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"item" => item_params}, socket) do
    save_item(socket, socket.assigns.action, item_params)
  end

  defp save_item(socket, :edit, item_params) do
    case Catalog.update_item(socket.assigns.item, item_params, socket.assigns.current_user) do
      {:ok, item} ->
        {:noreply,
         socket
         |> put_flash(:info, "Item \"#{item.name}\" updated")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_item(socket, :new, item_params) do
    BoilerworksWeb.Plugs.LiveAuth.require_permission!(socket, "item.create")

    case Catalog.create_item(item_params, socket.assigns.current_user) do
      {:ok, item} ->
        {:noreply,
         socket
         |> put_flash(:info, "Item \"#{item.name}\" created")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-semibold leading-8 text-zinc-100"><%= @title %></h2>

      <.simple_form
        for={@form}
        id="item-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:sku]} type="text" label="SKU" />
        <.input field={@form[:price]} type="number" label="Price" step="0.01" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input
          field={@form[:category_id]}
          type="select"
          label="Category"
          prompt="Select a category"
          options={Enum.map(@categories, &{&1.name, &1.id})}
        />

        <:actions>
          <.button phx-disable-with="Saving...">Save Item</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
