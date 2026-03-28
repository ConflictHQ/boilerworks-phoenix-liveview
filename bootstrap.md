# Boilerworks Phoenix + LiveView -- Bootstrap

## Prerequisites

- Docker and Docker Compose

No local Elixir/Erlang installation required. Everything runs in Docker.

## Setup

```bash
cd docker
docker compose up -d --build
```

First boot takes ~60 seconds (dependency compilation, asset build, migrations, seed data).

## Verify

```bash
# Health check
curl http://localhost:4000/health

# Open in browser
open http://localhost:4000
```

Login with `admin@boilerworks.dev` / `password1234`.

## Development

Source files are volume-mounted. Changes to `.ex` and `.heex` files trigger automatic recompilation and live reload.

### Running mix commands

```bash
cd docker
docker compose exec app mix <command>
```

### Running tests

```bash
docker compose exec app sh -c "MIX_ENV=test mix test"
```

### Creating a migration

```bash
docker compose exec app mix ecto.gen.migration <name>
docker compose exec app mix ecto.migrate
```

### Resetting the database

```bash
docker compose exec app mix ecto.reset
```

## Conventions

See the [stack primer](../primers/phoenix-liveview/PRIMER.md) for full architecture decisions and patterns.

### Key patterns

- **UUID primary keys** on all tables (`@primary_key {:id, :binary_id, autogenerate: true}`)
- **Soft deletes** via `deleted_at`/`deleted_by` fields, filtered in all queries
- **Audit trails** via `created_by`/`updated_by` fields on all mutable records
- **Group-based RBAC** -- permissions are assigned to groups, users belong to groups
- **Permission checks** in every LiveView `mount/3` via `require_permission!/2`
- **PubSub** for real-time updates across connected clients
- **Feature toggles** via environment variables (`FEATURE_FORMS`, `FEATURE_WORKFLOWS`)

### Code style

- `mix format` (2-space indentation, 98 char line length)
- Credo for linting
- snake_case for functions/variables, CamelCase for modules
