defmodule BoilerworksWeb.FormLive.Submit do
  use BoilerworksWeb, :live_view

  alias Boilerworks.Forms
  import BoilerworksWeb.Plugs.LiveAuth, only: [require_permission!: 2]

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    require_permission!(socket, "form.submit")
    form_def = Forms.get_form_definition!(id)
    fields = get_in(form_def.schema, ["fields"]) || []

    initial_data =
      Enum.reduce(fields, %{}, fn field, acc ->
        Map.put(acc, field["name"], "")
      end)

    {:ok,
     assign(socket,
       form_definition: form_def,
       fields: fields,
       form_data: initial_data,
       errors: [],
       page_title: "Submit: #{form_def.name}"
     )}
  end

  @impl true
  def handle_event("validate", %{"submission" => params}, socket) do
    {:noreply, assign(socket, form_data: params, errors: [])}
  end

  @impl true
  def handle_event("submit", %{"submission" => params}, socket) do
    form_def = socket.assigns.form_definition

    case Forms.validate_submission_data(form_def, params) do
      :ok ->
        case Forms.create_submission(
               %{"data" => params, "form_definition_id" => form_def.id, "status" => "submitted"},
               socket.assigns.current_user
             ) do
          {:ok, _submission} ->
            {:noreply,
             socket
             |> put_flash(:info, "Form submitted")
             |> push_navigate(to: ~p"/forms/#{form_def}")}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to submit form")}
        end

      {:error, errors} ->
        {:noreply, assign(socket, errors: errors)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Submit: {@form_definition.name}
    </.header>

    <div class="mt-8">
      <form phx-change="validate" phx-submit="submit" class="space-y-6">
        <div :for={field <- @fields}>
          <label class="block text-sm font-semibold leading-6 text-zinc-300">
            {field["label"] || field["name"]}
            <span :if={field["required"]} class="text-rose-400">*</span>
          </label>

          {render_field(field, @form_data, @errors)}
        </div>

        <div class="flex gap-4">
          <.button type="submit" phx-disable-with="Submitting...">Submit</.button>
          <.link
            navigate={~p"/forms/#{@form_definition}"}
            class="rounded-lg bg-zinc-700 hover:bg-zinc-600 py-2 px-3 text-sm font-semibold text-zinc-200"
          >
            Cancel
          </.link>
        </div>
      </form>
    </div>
    """
  end

  defp render_field(%{"type" => "textarea"} = field, form_data, errors) do
    name = field["name"]
    value = Map.get(form_data, name, "")
    field_errors = for {^name, msg} <- errors, do: msg

    assigns = %{name: name, value: value, errors: field_errors}

    ~H"""
    <textarea
      name={"submission[#{@name}]"}
      class={[
        "mt-2 block w-full rounded-lg border-zinc-600 bg-zinc-700 text-zinc-200 focus:ring-0 sm:text-sm",
        @errors != [] && "border-rose-400"
      ]}
      rows="4"
    ><%= @value %></textarea>
    <p :for={msg <- @errors} class="mt-1 text-sm text-rose-400">{msg}</p>
    """
  end

  defp render_field(%{"type" => "select", "options" => options} = field, form_data, errors) do
    name = field["name"]
    value = Map.get(form_data, name, "")
    field_errors = for {^name, msg} <- errors, do: msg

    assigns = %{name: name, value: value, options: options, errors: field_errors}

    ~H"""
    <select
      name={"submission[#{@name}]"}
      class="mt-2 block w-full rounded-lg border-zinc-600 bg-zinc-700 text-zinc-200 focus:ring-0 sm:text-sm"
    >
      <option value="">Select...</option>
      <option :for={opt <- @options} value={opt} selected={opt == @value}>{opt}</option>
    </select>
    <p :for={msg <- @errors} class="mt-1 text-sm text-rose-400">{msg}</p>
    """
  end

  defp render_field(%{"type" => "checkbox"} = field, form_data, errors) do
    name = field["name"]
    value = Map.get(form_data, name, "")
    field_errors = for {^name, msg} <- errors, do: msg

    assigns = %{name: name, value: value, errors: field_errors}

    ~H"""
    <div class="mt-2">
      <input type="hidden" name={"submission[#{@name}]"} value="false" />
      <input
        type="checkbox"
        name={"submission[#{@name}]"}
        value="true"
        checked={@value == "true"}
        class="rounded border-zinc-600 bg-zinc-700 text-emerald-500 focus:ring-0"
      />
    </div>
    <p :for={msg <- @errors} class="mt-1 text-sm text-rose-400">{msg}</p>
    """
  end

  defp render_field(%{"type" => "number"} = field, form_data, errors) do
    render_input_field(field, form_data, errors, "number")
  end

  defp render_field(field, form_data, errors) do
    render_input_field(field, form_data, errors, "text")
  end

  defp render_input_field(field, form_data, errors, type) do
    name = field["name"]
    value = Map.get(form_data, name, "")
    field_errors = for {^name, msg} <- errors, do: msg

    assigns = %{name: name, value: value, type: type, errors: field_errors}

    ~H"""
    <input
      type={@type}
      name={"submission[#{@name}]"}
      value={@value}
      class={[
        "mt-2 block w-full rounded-lg border-zinc-600 bg-zinc-700 text-zinc-200 focus:ring-0 sm:text-sm",
        @errors != [] && "border-rose-400"
      ]}
    />
    <p :for={msg <- @errors} class="mt-1 text-sm text-rose-400">{msg}</p>
    """
  end
end
