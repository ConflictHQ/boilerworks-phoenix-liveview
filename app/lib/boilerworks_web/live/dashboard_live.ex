defmodule BoilerworksWeb.DashboardLive do
  use BoilerworksWeb, :live_view

  alias Boilerworks.{Catalog, Forms, Workflows}

  @impl true
  def mount(_params, _session, socket) do
    items = Catalog.list_items()
    categories = Catalog.list_categories()
    form_definitions = Forms.list_form_definitions()
    workflow_definitions = Workflows.list_workflow_definitions()

    {:ok,
     assign(socket,
       page_title: "Dashboard",
       item_count: length(items),
       category_count: length(categories),
       form_count: length(form_definitions),
       workflow_count: length(workflow_definitions)
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-2xl font-bold text-zinc-100 mb-8">Dashboard</h2>

      <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
        <.stat_card title="Items" count={@item_count} href={~p"/items"} color="emerald" />
        <.stat_card title="Categories" count={@category_count} href={~p"/categories"} color="blue" />
        <.stat_card title="Forms" count={@form_count} href={~p"/forms"} color="purple" />
        <.stat_card title="Workflows" count={@workflow_count} href={~p"/workflows"} color="amber" />
      </div>

      <div class="mt-12">
        <h3 class="text-lg font-semibold text-zinc-200 mb-4">Quick Actions</h3>
        <div class="flex gap-4">
          <.link
            navigate={~p"/items/new"}
            class="rounded-lg bg-emerald-600 hover:bg-emerald-500 px-4 py-2 text-sm font-semibold text-white"
          >
            New Item
          </.link>
          <.link
            navigate={~p"/categories/new"}
            class="rounded-lg bg-zinc-700 hover:bg-zinc-600 px-4 py-2 text-sm font-semibold text-zinc-200"
          >
            New Category
          </.link>
          <.link
            navigate={~p"/forms/new"}
            class="rounded-lg bg-zinc-700 hover:bg-zinc-600 px-4 py-2 text-sm font-semibold text-zinc-200"
          >
            New Form
          </.link>
          <.link
            navigate={~p"/workflows/new"}
            class="rounded-lg bg-zinc-700 hover:bg-zinc-600 px-4 py-2 text-sm font-semibold text-zinc-200"
          >
            New Workflow
          </.link>
        </div>
      </div>
    </div>
    """
  end

  defp stat_card(assigns) do
    color_classes = %{
      "emerald" => "bg-emerald-900/50 border-emerald-700 text-emerald-400",
      "blue" => "bg-blue-900/50 border-blue-700 text-blue-400",
      "purple" => "bg-purple-900/50 border-purple-700 text-purple-400",
      "amber" => "bg-amber-900/50 border-amber-700 text-amber-400"
    }

    assigns = assign(assigns, :color_class, Map.get(color_classes, assigns.color, ""))

    ~H"""
    <.link
      navigate={@href}
      class={"rounded-xl border p-6 #{@color_class} hover:opacity-80 transition"}
    >
      <p class="text-sm font-medium text-zinc-400">{@title}</p>
      <p class="mt-2 text-3xl font-bold">{@count}</p>
    </.link>
    """
  end
end
