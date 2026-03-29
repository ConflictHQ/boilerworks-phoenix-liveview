alias Boilerworks.Repo
alias Boilerworks.Accounts.{User, Group, Permission, UserGroup, GroupPermission}
alias Boilerworks.Catalog.{Category, Item}
alias Boilerworks.Forms.FormDefinition
alias Boilerworks.Workflows.WorkflowDefinition

# Permissions
permissions =
  [
    {"View Items", "item.view"},
    {"Create Items", "item.create"},
    {"Edit Items", "item.edit"},
    {"Delete Items", "item.delete"},
    {"View Categories", "category.view"},
    {"Create Categories", "category.create"},
    {"Edit Categories", "category.edit"},
    {"Delete Categories", "category.delete"},
    {"View Forms", "form.view"},
    {"Create Forms", "form.create"},
    {"Edit Forms", "form.edit"},
    {"Delete Forms", "form.delete"},
    {"Submit Forms", "form.submit"},
    {"View Workflows", "workflow.view"},
    {"Create Workflows", "workflow.create"},
    {"Edit Workflows", "workflow.edit"},
    {"Delete Workflows", "workflow.delete"},
    {"Manage Users", "user.manage"}
  ]
  |> Enum.map(fn {name, slug} ->
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Repo.insert!(
      %Permission{name: name, slug: slug, description: name, inserted_at: now, updated_at: now},
      on_conflict: :nothing,
      conflict_target: :slug
    )
  end)

# Fetch all permissions fresh (on_conflict: :nothing may return nil id)
all_permissions = Repo.all(Permission)

# Groups
admin_group =
  Repo.insert!(
    %Group{name: "Administrators", slug: "admin", description: "Full system access"},
    on_conflict: :nothing,
    conflict_target: :slug
  )

editor_group =
  Repo.insert!(
    %Group{name: "Editors", slug: "editor", description: "Content management access"},
    on_conflict: :nothing,
    conflict_target: :slug
  )

viewer_group =
  Repo.insert!(
    %Group{name: "Viewers", slug: "viewer", description: "Read-only access"},
    on_conflict: :nothing,
    conflict_target: :slug
  )

# Fetch groups fresh
admin_group = Repo.get_by!(Group, slug: "admin")
editor_group = Repo.get_by!(Group, slug: "editor")
viewer_group = Repo.get_by!(Group, slug: "viewer")

# Admin gets all permissions
for perm <- all_permissions do
  Repo.insert!(
    %GroupPermission{group_id: admin_group.id, permission_id: perm.id},
    on_conflict: :nothing,
    conflict_target: [:group_id, :permission_id]
  )
end

# Editor gets view + create + edit
editor_slugs = ~w(item.view item.create item.edit category.view category.create category.edit form.view form.create form.edit form.submit workflow.view)

for perm <- Enum.filter(all_permissions, &(&1.slug in editor_slugs)) do
  Repo.insert!(
    %GroupPermission{group_id: editor_group.id, permission_id: perm.id},
    on_conflict: :nothing,
    conflict_target: [:group_id, :permission_id]
  )
end

# Viewer gets view-only
viewer_slugs = ~w(item.view category.view form.view workflow.view form.submit)

for perm <- Enum.filter(all_permissions, &(&1.slug in viewer_slugs)) do
  Repo.insert!(
    %GroupPermission{group_id: viewer_group.id, permission_id: perm.id},
    on_conflict: :nothing,
    conflict_target: [:group_id, :permission_id]
  )
end

# Admin user
{:ok, admin_user} =
  case Repo.get_by(User, email: "admin@boilerworks.dev") do
    nil ->
      %User{}
      |> User.registration_changeset(%{
        email: "admin@boilerworks.dev",
        password: "password1234",
        first_name: "Admin",
        last_name: "User"
      })
      |> Repo.insert()

    user ->
      {:ok, user}
  end

# Assign admin to admin group
Repo.insert!(
  %UserGroup{user_id: admin_user.id, group_id: admin_group.id},
  on_conflict: :nothing,
  conflict_target: [:user_id, :group_id]
)

# Sample categories
categories =
  for {name, desc} <- [
        {"Electronics", "Electronic devices and accessories"},
        {"Clothing", "Apparel and fashion"},
        {"Books", "Physical and digital books"},
        {"Home & Garden", "Home improvement and garden supplies"}
      ] do
    slug = name |> String.downcase() |> String.replace(~r/[^a-z0-9\s-]/, "") |> String.replace(~r/\s+/, "-")

    case Repo.get_by(Category, slug: slug) do
      nil ->
        {:ok, cat} =
          %Category{}
          |> Category.changeset(%{name: name, slug: slug, description: desc})
          |> Ecto.Changeset.put_change(:created_by_id, admin_user.id)
          |> Ecto.Changeset.put_change(:updated_by_id, admin_user.id)
          |> Repo.insert()

        cat

      cat ->
        cat
    end
  end

# Sample items
electronics = Enum.find(categories, &(&1.name == "Electronics"))

for {name, price, sku} <- [
      {"Wireless Keyboard", "49.99", "WK-001"},
      {"USB-C Hub", "29.99", "UCH-002"},
      {"Mechanical Mouse", "79.99", "MM-003"}
    ] do
  slug = name |> String.downcase() |> String.replace(~r/[^a-z0-9\s-]/, "") |> String.replace(~r/\s+/, "-")

  case Repo.get_by(Item, slug: slug) do
    nil ->
      %Item{}
      |> Item.changeset(%{name: name, slug: slug, price: price, sku: sku, category_id: electronics.id})
      |> Ecto.Changeset.put_change(:created_by_id, admin_user.id)
      |> Ecto.Changeset.put_change(:updated_by_id, admin_user.id)
      |> Repo.insert!()

    _ ->
      :ok
  end
end

# Sample form definition
case Repo.get_by(FormDefinition, slug: "contact-form") do
  nil ->
    %FormDefinition{}
    |> FormDefinition.changeset(%{
      name: "Contact Form",
      slug: "contact-form",
      description: "Basic contact form",
      schema: %{
        "fields" => [
          %{"name" => "full_name", "type" => "text", "label" => "Full Name", "required" => true},
          %{"name" => "email", "type" => "email", "label" => "Email Address", "required" => true},
          %{"name" => "subject", "type" => "select", "label" => "Subject", "required" => true, "options" => ["General Inquiry", "Support", "Sales", "Other"]},
          %{"name" => "message", "type" => "textarea", "label" => "Message", "required" => true}
        ]
      }
    })
    |> Ecto.Changeset.put_change(:created_by_id, admin_user.id)
    |> Ecto.Changeset.put_change(:updated_by_id, admin_user.id)
    |> Repo.insert!()

  _ ->
    :ok
end

# Sample workflow definition
case Repo.get_by(WorkflowDefinition, slug: "content-approval") do
  nil ->
    %WorkflowDefinition{}
    |> WorkflowDefinition.changeset(%{
      name: "Content Approval",
      slug: "content-approval",
      description: "Standard content review and approval workflow",
      initial_state: "draft",
      states: %{
        "draft" => %{"label" => "Draft"},
        "in_review" => %{"label" => "In Review"},
        "approved" => %{"label" => "Approved", "terminal" => true},
        "rejected" => %{"label" => "Rejected"}
      },
      transitions: [
        %{"name" => "submit_for_review", "from" => "draft", "to" => "in_review", "label" => "Submit for Review"},
        %{"name" => "approve", "from" => "in_review", "to" => "approved", "label" => "Approve"},
        %{"name" => "reject", "from" => "in_review", "to" => "rejected", "label" => "Reject"},
        %{"name" => "revise", "from" => "rejected", "to" => "draft", "label" => "Revise"}
      ]
    })
    |> Ecto.Changeset.put_change(:created_by_id, admin_user.id)
    |> Ecto.Changeset.put_change(:updated_by_id, admin_user.id)
    |> Repo.insert!()

  _ ->
    :ok
end

IO.puts("Seeds completed successfully!")
IO.puts("Admin user: admin@boilerworks.dev / password1234")
