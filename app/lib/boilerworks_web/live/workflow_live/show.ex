defmodule BoilerworksWeb.WorkflowLive.Show do
  use BoilerworksWeb, :live_view

  alias Boilerworks.Workflows
  import BoilerworksWeb.Plugs.LiveAuth, only: [require_permission!: 2]

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    require_permission!(socket, "workflow.view")
    workflow_def = Workflows.get_workflow_definition!(id)
    instances = Workflows.list_instances(id)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Boilerworks.PubSub, "workflow:#{id}")
    end

    {:ok,
     assign(socket,
       workflow_definition: workflow_def,
       instances: instances,
       page_title: workflow_def.name
     )}
  end

  @impl true
  def handle_event("create_instance", _params, socket) do
    wf = socket.assigns.workflow_definition

    case Workflows.create_instance(wf, %{}, socket.assigns.current_user) do
      {:ok, _instance} ->
        instances = Workflows.list_instances(wf.id)
        {:noreply, assign(socket, instances: instances) |> put_flash(:info, "Instance created")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to create instance")}
    end
  end

  @impl true
  def handle_event("transition", %{"instance_id" => instance_id, "transition" => transition_name}, socket) do
    instance = Workflows.get_instance!(instance_id)

    case Workflows.transition(instance, transition_name, socket.assigns.current_user) do
      {:ok, _updated} ->
        instances = Workflows.list_instances(socket.assigns.workflow_definition.id)
        {:noreply, assign(socket, instances: instances) |> put_flash(:info, "Transition applied")}

      {:error, :invalid_transition} ->
        {:noreply, put_flash(socket, :error, "Invalid transition")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Transition failed")}
    end
  end

  @impl true
  def handle_info({:instance_created, _instance}, socket) do
    instances = Workflows.list_instances(socket.assigns.workflow_definition.id)
    {:noreply, assign(socket, instances: instances)}
  end

  @impl true
  def handle_info({:instance_transitioned, _instance}, socket) do
    instances = Workflows.list_instances(socket.assigns.workflow_definition.id)
    {:noreply, assign(socket, instances: instances)}
  end

  @impl true
  def render(assigns) do
    states = assigns.workflow_definition.states || %{}
    transitions = assigns.workflow_definition.transitions || []
    assigns = assign(assigns, states: states, all_transitions: transitions)

    ~H"""
    <.header>
      <%= @workflow_definition.name %>
      <:actions>
        <.button phx-click="create_instance">New Instance</.button>
      </:actions>
    </.header>

    <div class="mt-8 space-y-8">
      <div>
        <h3 class="text-sm font-medium text-zinc-400 mb-3">States</h3>
        <div class="flex flex-wrap gap-2">
          <span
            :for={{state_name, config} <- @states}
            class={[
              "px-3 py-1 rounded-full text-sm font-medium",
              if(Map.get(config, "terminal"), do: "bg-emerald-900 text-emerald-300 border border-emerald-700", else: "bg-zinc-700 text-zinc-300 border border-zinc-600")
            ]}
          >
            <%= state_name %>
            <span :if={state_name == @workflow_definition.initial_state} class="text-xs text-zinc-500">(initial)</span>
            <span :if={Map.get(config, "terminal")} class="text-xs text-emerald-500">(terminal)</span>
          </span>
        </div>
      </div>

      <div>
        <h3 class="text-sm font-medium text-zinc-400 mb-3">Transitions</h3>
        <div class="space-y-2">
          <div :for={t <- @all_transitions} class="flex items-center gap-2 text-sm text-zinc-300">
            <span class="font-mono text-zinc-400"><%= t["from"] %></span>
            <span class="text-zinc-500">&rarr;</span>
            <span class="font-mono text-zinc-400"><%= t["to"] %></span>
            <span class="text-emerald-400">(<%= t["label"] || t["name"] %>)</span>
          </div>
        </div>
      </div>

      <div>
        <h3 class="text-sm font-medium text-zinc-400 mb-3">Instances (<%= length(@instances) %>)</h3>
        <div class="space-y-4">
          <div :for={instance <- @instances} class="rounded-lg border border-zinc-700 bg-zinc-800 p-4">
            <div class="flex items-center justify-between mb-3">
              <div class="flex items-center gap-3">
                <span class="px-2 py-1 rounded bg-zinc-700 text-sm font-mono text-zinc-300">
                  <%= instance.current_state %>
                </span>
                <span :if={instance.completed_at} class="text-xs text-emerald-400">completed</span>
              </div>
              <span class="text-xs text-zinc-500">
                <%= if instance.created_by, do: instance.created_by.email, else: "" %>
              </span>
            </div>

            <div :if={!instance.completed_at} class="flex gap-2">
              <%= for t <- available_transitions(instance, @all_transitions) do %>
                <button
                  phx-click="transition"
                  phx-value-instance_id={instance.id}
                  phx-value-transition={t["name"]}
                  class="rounded bg-emerald-600 hover:bg-emerald-500 px-3 py-1 text-xs font-semibold text-white"
                >
                  <%= t["label"] || t["name"] %>
                </button>
              <% end %>
            </div>
          </div>

          <p :if={@instances == []} class="text-sm text-zinc-500">No instances yet.</p>
        </div>
      </div>
    </div>

    <.back navigate={~p"/workflows"}>Back to workflows</.back>
    """
  end

  defp available_transitions(instance, all_transitions) do
    Enum.filter(all_transitions, fn t -> t["from"] == instance.current_state end)
  end
end
