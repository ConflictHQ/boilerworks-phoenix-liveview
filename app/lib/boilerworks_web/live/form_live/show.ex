defmodule BoilerworksWeb.FormLive.Show do
  use BoilerworksWeb, :live_view

  alias Boilerworks.Forms
  import BoilerworksWeb.Plugs.LiveAuth, only: [require_permission!: 2]

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    require_permission!(socket, "form.view")
    form_def = Forms.get_form_definition!(id)
    submissions = Forms.list_submissions(id)

    {:ok,
     assign(socket,
       form_definition: form_def,
       submissions: submissions,
       page_title: form_def.name
     )}
  end

  @impl true
  def render(assigns) do
    fields = get_in(assigns.form_definition.schema, ["fields"]) || []
    assigns = assign(assigns, :fields, fields)

    ~H"""
    <.header>
      {@form_definition.name}
      <:actions>
        <.link navigate={~p"/forms/#{@form_definition}/submit"}>
          <.button>Submit Form</.button>
        </.link>
      </:actions>
    </.header>

    <div class="mt-8 space-y-8">
      <div>
        <h3 class="text-sm font-medium text-zinc-400 mb-2">Description</h3>
        <p class="text-zinc-200">{@form_definition.description || "No description"}</p>
      </div>

      <div>
        <h3 class="text-sm font-medium text-zinc-400 mb-2">Fields</h3>
        <div class="space-y-2">
          <div
            :for={field <- @fields}
            class="flex items-center gap-4 rounded-lg bg-zinc-800 border border-zinc-700 px-4 py-3"
          >
            <span class="text-sm font-mono text-emerald-400">{field["type"]}</span>
            <span class="text-sm text-zinc-200">{field["label"] || field["name"]}</span>
            <span :if={field["required"]} class="text-xs text-rose-400">required</span>
          </div>
        </div>
      </div>

      <div>
        <h3 class="text-sm font-medium text-zinc-400 mb-2">Submissions ({length(@submissions)})</h3>
        <.table id="submissions" rows={@submissions}>
          <:col :let={sub} label="Status">{sub.status}</:col>
          <:col :let={sub} label="Submitted By">
            {if sub.submitted_by, do: sub.submitted_by.email, else: "-"}
          </:col>
          <:col :let={sub} label="Submitted At">{sub.inserted_at}</:col>
        </.table>
      </div>
    </div>

    <.back navigate={~p"/forms"}>Back to forms</.back>
    """
  end
end
