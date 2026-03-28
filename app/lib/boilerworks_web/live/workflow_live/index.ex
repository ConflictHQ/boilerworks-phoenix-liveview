defmodule BoilerworksWeb.WorkflowLive.Index do
  use BoilerworksWeb, :live_view

  alias Boilerworks.Workflows
  alias Boilerworks.Workflows.WorkflowDefinition
  import BoilerworksWeb.Plugs.LiveAuth, only: [require_permission!: 2]

  @impl true
  def mount(_params, _session, socket) do
    require_permission!(socket, "workflow.view")
    {:ok, assign(socket, workflow_definitions: Workflows.list_workflow_definitions())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, page_title: "Workflows", workflow_definition: nil)
  end

  defp apply_action(socket, :new, _params) do
    assign(socket, page_title: "New Workflow", workflow_definition: %WorkflowDefinition{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    assign(socket, page_title: "Edit Workflow", workflow_definition: Workflows.get_workflow_definition!(id))
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    workflow_def = Workflows.get_workflow_definition!(id)
    {:ok, _} = Workflows.delete_workflow_definition(workflow_def)
    {:noreply, assign(socket, workflow_definitions: Workflows.list_workflow_definitions())}
  end

  @impl true
  def handle_event("validate", %{"workflow_definition" => params}, socket) do
    changeset =
      (socket.assigns.workflow_definition || %WorkflowDefinition{})
      |> Workflows.change_workflow_definition(parse_workflow_params(params))
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"workflow_definition" => params}, socket) do
    save_workflow(socket, socket.assigns.live_action, parse_workflow_params(params))
  end

  defp save_workflow(socket, :new, params) do
    case Workflows.create_workflow_definition(params, socket.assigns.current_user) do
      {:ok, _wf} ->
        {:noreply,
         socket
         |> put_flash(:info, "Workflow created")
         |> push_patch(to: ~p"/workflows")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_workflow(socket, :edit, params) do
    case Workflows.update_workflow_definition(socket.assigns.workflow_definition, params, socket.assigns.current_user) do
      {:ok, _wf} ->
        {:noreply,
         socket
         |> put_flash(:info, "Workflow updated")
         |> push_patch(to: ~p"/workflows")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp parse_workflow_params(params) do
    states_json = Map.get(params, "states_json", "")
    transitions_json = Map.get(params, "transitions_json", "")

    states = case Jason.decode(states_json) do
      {:ok, decoded} when is_map(decoded) -> decoded
      _ -> nil
    end

    transitions = case Jason.decode(transitions_json) do
      {:ok, decoded} when is_list(decoded) -> decoded
      _ -> nil
    end

    params
    |> Map.put("states", states)
    |> Map.put("transitions", transitions)
    |> Map.delete("states_json")
    |> Map.delete("transitions_json")
  end

  @impl true
  def render(assigns) do
    assigns =
      if assigns.live_action in [:new, :edit] do
        wf = assigns.workflow_definition || %WorkflowDefinition{}
        changeset = Workflows.change_workflow_definition(wf)

        states_json =
          if wf.states,
            do: Jason.encode!(wf.states, pretty: true),
            else: "{\n  \"draft\": {\"label\": \"Draft\"},\n  \"published\": {\"label\": \"Published\", \"terminal\": true}\n}"

        transitions_json =
          if wf.transitions,
            do: Jason.encode!(wf.transitions, pretty: true),
            else: "[\n  {\"name\": \"publish\", \"from\": \"draft\", \"to\": \"published\", \"label\": \"Publish\"}\n]"

        assign(assigns, form: to_form(changeset), states_json: states_json, transitions_json: transitions_json)
      else
        assigns
      end

    ~H"""
    <.header>
      Workflows
      <:actions>
        <.link patch={~p"/workflows/new"}>
          <.button>New Workflow</.button>
        </.link>
      </:actions>
    </.header>

    <div class="mt-6">
      <.table id="workflow-definitions" rows={@workflow_definitions}>
        <:col :let={wf} label="Name"><%= wf.name %></:col>
        <:col :let={wf} label="Slug"><%= wf.slug %></:col>
        <:col :let={wf} label="Initial State"><%= wf.initial_state %></:col>
        <:col :let={wf} label="Active"><%= if wf.is_active, do: "Yes", else: "No" %></:col>
        <:action :let={wf}>
          <.link navigate={~p"/workflows/#{wf}"}>View</.link>
        </:action>
        <:action :let={wf}>
          <.link patch={~p"/workflows/#{wf}/edit"}>Edit</.link>
        </:action>
        <:action :let={wf}>
          <.link phx-click={JS.push("delete", value: %{id: wf.id})} data-confirm="Are you sure?">
            Delete
          </.link>
        </:action>
      </.table>
    </div>

    <.modal :if={@live_action in [:new, :edit]} id="workflow-modal" show on_cancel={JS.patch(~p"/workflows")}>
      <div>
        <h2 class="text-lg font-semibold leading-8 text-zinc-100"><%= @page_title %></h2>

        <.simple_form
          for={@form}
          id="workflow-form"
          phx-change="validate"
          phx-submit="save"
        >
          <.input field={@form[:name]} type="text" label="Name" />
          <.input field={@form[:description]} type="textarea" label="Description" />
          <.input field={@form[:initial_state]} type="text" label="Initial State" />
          <.input field={@form[:is_active]} type="checkbox" label="Active" />

          <div>
            <label class="block text-sm font-semibold leading-6 text-zinc-300">States (JSON)</label>
            <textarea
              name="workflow_definition[states_json]"
              class="mt-2 block w-full rounded-lg border-zinc-600 bg-zinc-700 text-zinc-200 focus:ring-0 sm:text-sm font-mono"
              rows="6"
            ><%= if assigns[:states_json], do: @states_json, else: "" %></textarea>
          </div>

          <div>
            <label class="block text-sm font-semibold leading-6 text-zinc-300">Transitions (JSON)</label>
            <textarea
              name="workflow_definition[transitions_json]"
              class="mt-2 block w-full rounded-lg border-zinc-600 bg-zinc-700 text-zinc-200 focus:ring-0 sm:text-sm font-mono"
              rows="6"
            ><%= if assigns[:transitions_json], do: @transitions_json, else: "" %></textarea>
          </div>

          <:actions>
            <.button phx-disable-with="Saving...">Save Workflow</.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end
end
