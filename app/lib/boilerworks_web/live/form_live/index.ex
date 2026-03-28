defmodule BoilerworksWeb.FormLive.Index do
  use BoilerworksWeb, :live_view

  alias Boilerworks.Forms
  alias Boilerworks.Forms.FormDefinition
  import BoilerworksWeb.Plugs.LiveAuth, only: [require_permission!: 2]

  @impl true
  def mount(_params, _session, socket) do
    require_permission!(socket, "form.view")
    {:ok, assign(socket, form_definitions: Forms.list_form_definitions())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, page_title: "Forms", form_definition: nil)
  end

  defp apply_action(socket, :new, _params) do
    assign(socket, page_title: "New Form", form_definition: %FormDefinition{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    assign(socket, page_title: "Edit Form", form_definition: Forms.get_form_definition!(id))
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    form_def = Forms.get_form_definition!(id)
    {:ok, _} = Forms.delete_form_definition(form_def)
    {:noreply, assign(socket, form_definitions: Forms.list_form_definitions())}
  end

  @impl true
  def handle_event("validate", %{"form_definition" => params}, socket) do
    changeset =
      (socket.assigns.form_definition || %FormDefinition{})
      |> Forms.change_form_definition(parse_form_definition_params(params))
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"form_definition" => params}, socket) do
    save_form_definition(socket, socket.assigns.live_action, parse_form_definition_params(params))
  end

  defp save_form_definition(socket, :new, params) do
    case Forms.create_form_definition(params, socket.assigns.current_user) do
      {:ok, _form_def} ->
        {:noreply,
         socket
         |> put_flash(:info, "Form created")
         |> push_patch(to: ~p"/forms")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_form_definition(socket, :edit, params) do
    case Forms.update_form_definition(socket.assigns.form_definition, params, socket.assigns.current_user) do
      {:ok, _form_def} ->
        {:noreply,
         socket
         |> put_flash(:info, "Form updated")
         |> push_patch(to: ~p"/forms")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp parse_form_definition_params(params) do
    schema_json = Map.get(params, "schema_json", "")

    schema =
      case Jason.decode(schema_json) do
        {:ok, decoded} -> decoded
        _ -> nil
      end

    params
    |> Map.put("schema", schema)
    |> Map.delete("schema_json")
  end

  @impl true
  def render(assigns) do
    assigns =
      if assigns.live_action in [:new, :edit] do
        form_def = assigns.form_definition || %FormDefinition{}
        changeset = Forms.change_form_definition(form_def)
        schema_json = if form_def.schema, do: Jason.encode!(form_def.schema, pretty: true), else: "{\n  \"fields\": []\n}"
        assign(assigns, form: to_form(changeset), schema_json: schema_json)
      else
        assigns
      end

    ~H"""
    <.header>
      Forms
      <:actions>
        <.link patch={~p"/forms/new"}>
          <.button>New Form</.button>
        </.link>
      </:actions>
    </.header>

    <div class="mt-6">
      <.table id="form-definitions" rows={@form_definitions}>
        <:col :let={form_def} label="Name"><%= form_def.name %></:col>
        <:col :let={form_def} label="Slug"><%= form_def.slug %></:col>
        <:col :let={form_def} label="Active"><%= if form_def.is_active, do: "Yes", else: "No" %></:col>
        <:action :let={form_def}>
          <.link navigate={~p"/forms/#{form_def}"}>View</.link>
        </:action>
        <:action :let={form_def}>
          <.link patch={~p"/forms/#{form_def}/edit"}>Edit</.link>
        </:action>
        <:action :let={form_def}>
          <.link phx-click={JS.push("delete", value: %{id: form_def.id})} data-confirm="Are you sure?">
            Delete
          </.link>
        </:action>
      </.table>
    </div>

    <.modal :if={@live_action in [:new, :edit]} id="form-definition-modal" show on_cancel={JS.patch(~p"/forms")}>
      <div>
        <h2 class="text-lg font-semibold leading-8 text-zinc-100"><%= @page_title %></h2>

        <.simple_form
          for={@form}
          id="form-definition-form"
          phx-change="validate"
          phx-submit="save"
        >
          <.input field={@form[:name]} type="text" label="Name" />
          <.input field={@form[:description]} type="textarea" label="Description" />
          <.input field={@form[:is_active]} type="checkbox" label="Active" />

          <div>
            <label class="block text-sm font-semibold leading-6 text-zinc-300">Schema (JSON)</label>
            <textarea
              name="form_definition[schema_json]"
              class="mt-2 block w-full rounded-lg border-zinc-600 bg-zinc-700 text-zinc-200 focus:ring-0 sm:text-sm font-mono"
              rows="10"
            ><%= if assigns[:schema_json], do: @schema_json, else: "" %></textarea>
            <p class="mt-1 text-xs text-zinc-500">JSON with a fields array. Each field has: name, type, label, required</p>
          </div>

          <:actions>
            <.button phx-disable-with="Saving...">Save Form</.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end
end
