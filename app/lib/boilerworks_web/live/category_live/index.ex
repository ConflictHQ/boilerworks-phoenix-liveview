defmodule BoilerworksWeb.CategoryLive.Index do
  use BoilerworksWeb, :live_view

  alias Boilerworks.Catalog
  alias Boilerworks.Catalog.Category
  import BoilerworksWeb.Plugs.LiveAuth, only: [require_permission!: 2]

  @impl true
  def mount(_params, _session, socket) do
    require_permission!(socket, "category.view")
    {:ok, assign(socket, categories: Catalog.list_categories(), search: "")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, page_title: "Categories", category: nil)
  end

  defp apply_action(socket, :new, _params) do
    assign(socket, page_title: "New Category", category: %Category{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    assign(socket, page_title: "Edit Category", category: Catalog.get_category!(id))
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    categories = Catalog.list_categories(search: search)
    {:noreply, assign(socket, categories: categories, search: search)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    category = Catalog.get_category!(id)
    {:ok, _} = Catalog.delete_category(category, socket.assigns.current_user)
    {:noreply, assign(socket, categories: Catalog.list_categories(search: socket.assigns.search))}
  end

  @impl true
  def handle_event("validate", %{"category" => category_params}, socket) do
    changeset =
      (socket.assigns.category || %Category{})
      |> Catalog.change_category(category_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"category" => category_params}, socket) do
    save_category(socket, socket.assigns.live_action, category_params)
  end

  defp save_category(socket, :new, category_params) do
    case Catalog.create_category(category_params, socket.assigns.current_user) do
      {:ok, _category} ->
        {:noreply,
         socket
         |> put_flash(:info, "Category created")
         |> push_patch(to: ~p"/categories")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_category(socket, :edit, category_params) do
    case Catalog.update_category(
           socket.assigns.category,
           category_params,
           socket.assigns.current_user
         ) do
      {:ok, _category} ->
        {:noreply,
         socket
         |> put_flash(:info, "Category updated")
         |> push_patch(to: ~p"/categories")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    assigns =
      if assigns.live_action in [:new, :edit] do
        category = assigns.category || %Category{}
        changeset = Catalog.change_category(category)
        assign(assigns, form: to_form(changeset))
      else
        assigns
      end

    ~H"""
    <.header>
      Categories
      <:actions>
        <.link patch={~p"/categories/new"}>
          <.button>New Category</.button>
        </.link>
      </:actions>
    </.header>

    <div class="mt-6">
      <form phx-change="search" class="mb-6">
        <input
          type="text"
          name="search"
          value={@search}
          placeholder="Search categories..."
          phx-debounce="300"
          class="w-full rounded-lg border-zinc-600 bg-zinc-700 text-zinc-200 focus:ring-0 sm:text-sm"
        />
      </form>

      <.table id="categories" rows={@categories}>
        <:col :let={category} label="Name">{category.name}</:col>
        <:col :let={category} label="Slug">{category.slug}</:col>
        <:col :let={category} label="Description">{category.description || "-"}</:col>
        <:action :let={category}>
          <.link patch={~p"/categories/#{category}/edit"}>Edit</.link>
        </:action>
        <:action :let={category}>
          <.link phx-click={JS.push("delete", value: %{id: category.id})} data-confirm="Are you sure?">
            Delete
          </.link>
        </:action>
      </.table>
    </div>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="category-modal"
      show
      on_cancel={JS.patch(~p"/categories")}
    >
      <div>
        <h2 class="text-lg font-semibold leading-8 text-zinc-100">{@page_title}</h2>

        <.simple_form
          for={@form}
          id="category-form"
          phx-change="validate"
          phx-submit="save"
        >
          <.input field={@form[:name]} type="text" label="Name" />
          <.input field={@form[:description]} type="textarea" label="Description" />

          <:actions>
            <.button phx-disable-with="Saving...">Save Category</.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end
end
