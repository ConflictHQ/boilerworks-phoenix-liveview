# Agents -- Boilerworks Phoenix + LiveView

Primary conventions doc: [`bootstrap.md`](bootstrap.md)

Read it before writing any code.

## Stack summary

- Elixir 1.17 / Phoenix 1.7 / LiveView 1.1
- Ecto 3.13 with PostgreSQL 16
- Oban for background jobs
- Tailwind CSS (dark theme)
- Docker-only development (no local Elixir)

## Key files

- `app/lib/boilerworks_web/router.ex` -- All routes
- `app/lib/boilerworks_web/components/core_components.ex` -- Shared UI components
- `app/lib/boilerworks_web/plugs/auth.ex` -- Session auth plug
- `app/lib/boilerworks_web/plugs/live_auth.ex` -- LiveView auth hooks
- `app/lib/boilerworks/authorization.ex` -- Permission checks
- `app/priv/repo/seeds.exs` -- Default users, groups, permissions, sample data

## Running commands

All Elixir/Mix commands must run inside Docker:

```bash
cd docker
docker compose exec app mix <command>
docker compose exec app sh -c "MIX_ENV=test mix test"
```

## Permission system

Permissions are group-based. Check with `Authorization.has_permission?(user, "permission.slug")`.
In LiveViews, use `require_permission!(socket, "permission.slug")` in `mount/3`.

Permission slugs follow the pattern `resource.action` (e.g., `item.view`, `item.create`).

## Forms engine

Form definitions use JSON schema stored in the `schema` column:

```json
{
  "fields": [
    {"name": "field_name", "type": "text|email|number|textarea|select|checkbox", "label": "Display Label", "required": true}
  ]
}
```

Select fields include an `"options"` array.

## Workflow engine

Workflow definitions have states (map) and transitions (array):

```json
// states
{"draft": {"label": "Draft"}, "approved": {"label": "Approved", "terminal": true}}

// transitions
[{"name": "approve", "from": "draft", "to": "approved", "label": "Approve"}]
```

Terminal states mark instances as completed.
