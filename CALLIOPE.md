# Calliope — Boilerworks Phoenix + LiveView
<!-- Agent shim for https://github.com/calliopeai/calliope-cli -->

Primary conventions doc: [`bootstrap.md`](bootstrap.md)
Context seed: [`memory.md`](memory.md)

Read both before writing any code.

---

## Project-specific notes

- Stack: Phoenix 1.7 / Elixir 1.17, LiveView 1.1, Ecto 3.13, PostgreSQL 16, Oban, Redis 7.
- UUID binary primary keys; soft deletes (`deleted_at`/`deleted_by`); audit trails (`created_by`/`updated_by`).
- Group-based RBAC — every LiveView `mount/3` checks `require_permission!/2`; permissions are never user-based.
- Real-time updates via Phoenix PubSub; forms and workflows gate behind `FEATURE_FORMS`/`FEATURE_WORKFLOWS` toggles.
- Everything runs in Docker (`cd docker && docker compose up -d --build`); app on :8000. Code style: `mix format` (98-col) + Credo.
