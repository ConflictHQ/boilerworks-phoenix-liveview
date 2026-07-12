# Boilerworks Memory

This file is the **AI context seed** for the Boilerworks Phoenix + LiveView template. It captures decisions, constraints, and non-obvious facts that are not derivable from reading a single file.

For conventions and patterns, see [`bootstrap.md`](bootstrap.md).

---

## Template purpose

Real-time Elixir starter: Phoenix 1.7 with LiveView, server-rendered UI over WebSocket, Tailwind CSS dark theme. Ships with session auth, group-based RBAC, Items/Categories CRUD, a JSON-schema forms engine, a JSON-defined workflow (state machine) engine, and Oban background jobs.

## Key architectural decisions

| Decision | Why |
|---|---|
| LiveView over a JS framework | All interactive UI is server-rendered LiveView; real-time updates fan out via Phoenix.PubSub subscriptions in `mount/3` |
| Session auth, not JWT | Bcrypt password hashing (`bcrypt_elixir`); session tokens in httpOnly cookies; custom phx.gen.auth-style pattern |
| Group-based RBAC | Users -> groups -> permissions; every LiveView `mount/3` guards with `require_permission!/2`; slugs follow `resource.action` |
| UUID primary keys everywhere | `@primary_key {:id, :binary_id, autogenerate: true}` on all schemas |
| Soft deletes + audit trails | `deleted_at`/`deleted_by` filtered in all queries; `created_by`/`updated_by` on mutable records |
| Oban on Postgres | Background jobs need no extra broker; `testing: :inline` in test config |
| Docker-only development | No local Elixir/Erlang required; source volume-mounted with live reload |

## Things that bite newcomers

- **All mix commands run inside Docker** -- `cd docker && docker compose exec app mix <command>`. The app is published on host port 8000 (container 4000).
- **Redis is declared but unused** -- compose runs redis:7 and injects `REDIS_URL`, and mix.exs pulls `redix`, but no code references either; PubSub uses the default in-memory adapter (`app/lib/boilerworks/application.ex`). Known P1; see the fleet-audit issue (#18) before wiring or removing it.
- **Seed credentials** are `admin@boilerworks.dev` / `password1234` (`app/priv/repo/seeds.exs`). Dev-only; change before any real deployment.
- **Feature toggles are env-driven** -- `FEATURE_FORMS` / `FEATURE_WORKFLOWS` must equal the string `"true"` (`app/lib/boilerworks/features.ex`).
- **Forms engine** stores JSON schema in the `schema` column; select fields need an `"options"` array.
- **Workflow engine** definitions are states (map) + transitions (array); states with `"terminal": true` complete the instance.
- **Code style**: `mix format` (98 char line length), Credo for linting, dialyzer PLTs cached in `priv/plts`.

## Release status

Template is feature-complete. CI (lint, build --warnings-as-errors, test + coveralls with Postgres 16 service, dialyzer, docker build) is green. Pending: Phoenix 1.8 upgrade is blocked by the `~> 1.7.14` pin in `app/mix.exs` (fleet-audit issue #18).
