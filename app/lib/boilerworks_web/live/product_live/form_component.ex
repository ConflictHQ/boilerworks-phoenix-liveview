defmodule BoilerworksWeb.ProductLive.FormComponent do
  use BoilerworksWeb, :live_component

  alias Boilerworks.Catalog

  @impl true
  def update(%{product: product} = assigns, socket) do
    categories = Catalog.list_categories()
    changeset = Catalog.change_product(product)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(categories: categories)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"product" => product_params}, socket) do
    changeset =
      socket.assigns.product
      |> Catalog.change_product(product_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"product" => product_params}, socket) do
    save_product(socket, socket.assigns.action, product_params)
  end

  defp save_product(socket, :edit, product_params) do
    case Catalog.update_product(socket.assigns.product, product_params, socket.assigns.current_user) do
      {:ok, product} ->
        {:noreply,
         socket
         |> put_flash(:info, "Product \"#{product.name}\" updated")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_product(socket, :new, product_params) do
    BoilerworksWeb.Plugs.LiveAuth.require_permission!(socket, "product.create")

    case Catalog.create_product(product_params, socket.assigns.current_user) do
      {:ok, product} ->
        {:noreply,
         socket
         |> put_flash(:info, "Product \"#{product.name}\" created")
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
        id="product-form"
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
          <.button phx-disable-with="Saving...">Save Product</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
