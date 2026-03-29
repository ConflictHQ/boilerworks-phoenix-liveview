# Claude -- Boilerworks Phoenix + LiveView

Primary conventions doc: [`bootstrap.md`](bootstrap.md)

Read it before writing any code.

## Stack

- **Backend**: Phoenix 1.7 (Elixir 1.17)
- **Frontend**: LiveView 1.1
- **ORM**: Ecto 3.13
- **Database**: PostgreSQL 16
- **Jobs**: Oban
- **Cache/PubSub**: Redis 7
- **Auth**: Session-based (custom phx.gen.auth pattern)
- **Permissions**: Group-based RBAC

## Quick Reference

### Running locally

```bash
cd docker
docker compose up -d --build
```

- **App**: http://localhost:8000
- **Postgres**: localhost:5432
- **Redis**: localhost:6379
- **Admin login**: admin@boilerworks.dev / password1234

### Running tests

```bash
cd docker
docker compose exec app sh -c "MIX_ENV=test mix test"
```

### Key paths

| Path | Purpose |
|------|---------|
| `app/lib/boilerworks/` | Business logic (contexts) |
| `app/lib/boilerworks_web/` | Web layer (router, controllers, LiveViews) |
| `app/lib/boilerworks_web/live/` | LiveView modules |
| `app/lib/boilerworks_web/components/` | Reusable components |
| `app/priv/repo/migrations/` | Ecto migrations |
| `app/priv/repo/seeds.exs` | Seed data |
| `app/test/` | ExUnit tests |
| `docker/` | Docker Compose + Dockerfile |

### Conventions

- UUID binary primary keys on all tables
- Soft deletes via `deleted_at`/`deleted_by` fields
- Audit trails via `created_by`/`updated_by` fields
- Permissions are group-based, never user-based
- All LiveView mounts check permissions via `require_permission!/2`
- Real-time updates via Phoenix PubSub
- Forms engine: JSON schema with dynamic LiveView rendering
- Workflow engine: state machine with transition logging
- Feature toggles via `FEATURE_FORMS` and `FEATURE_WORKFLOWS` env vars

### Adding a new CRUD resource

1. Create Ecto schema in `app/lib/boilerworks/<context>/`
2. Create context module in `app/lib/boilerworks/<context>.ex`
3. Create migration in `app/priv/repo/migrations/`
4. Create LiveView in `app/lib/boilerworks_web/live/<resource>_live/`
5. Add routes in `app/lib/boilerworks_web/router.ex`
6. Add permissions to seeds
7. Write tests
