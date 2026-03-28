# Boilerworks Phoenix + LiveView

> Real-time Elixir applications with Phoenix 1.7 and LiveView for collaborative and interactive experiences.

Phoenix with LiveView for applications that demand real-time updates, collaborative editing, or persistent WebSocket connections. The BEAM VM gives you fault tolerance and massive concurrency out of the box.

## Features

- **Phoenix 1.7 + LiveView** -- Server-rendered real-time UI over WebSocket
- **Session-based auth** -- Bcrypt password hashing, session tokens, httpOnly cookies
- **Group-based RBAC** -- Permissions assigned to groups, never directly to users
- **Products + Categories CRUD** -- Full LiveView CRUD with real-time PubSub updates
- **Forms engine** -- JSON schema definitions, dynamic LiveView rendering, validation
- **Workflow engine** -- State machine with transitions, logging, real-time updates
- **Boilerworks dark admin theme** -- Tailwind CSS dark mode throughout
- **Oban background jobs** -- Postgres-backed job queue
- **Docker Compose** -- Full development stack (Phoenix, Postgres, Redis)
- **CI pipeline** -- GitHub Actions (lint, build, test, Docker build)

## Quick Start

```bash
cd docker
docker compose up -d --build
```

Wait ~60 seconds for first boot (dependency compilation, asset build, migrations, seeds).

- **App**: http://localhost:4000
- **Admin login**: admin@boilerworks.dev / password1234
- **Health check**: http://localhost:4000/health

## Running Tests

```bash
cd docker
docker compose exec app sh -c "MIX_ENV=test mix test"
```

## Ports

| Service | Port |
|---------|------|
| Phoenix | 4000 |
| PostgreSQL | 5445 |
| Redis | 6388 |

## Architecture

```
Browser
  +-- Phoenix LiveView (WebSocket connection)
        |
  Phoenix 1.7 (Plug pipeline, Ecto, PubSub)
        |-- Oban (async jobs, Postgres-backed)
        |-- Postgres 16 (via Ecto)
        +-- Redis 7 (PubSub adapter)
```

## Project Structure

```
app/
  config/            -- Runtime and compile-time config
  lib/
    boilerworks/     -- Business logic contexts
      accounts/      -- Users, groups, permissions, tokens
      authorization/ -- RBAC permission checks
      catalog/       -- Products and categories
      forms/         -- Form definitions and submissions
      workflows/     -- Workflow definitions, instances, transitions
    boilerworks_web/ -- Web layer
      components/    -- Core UI components + layouts
      controllers/   -- Auth, health controllers
      live/          -- LiveView modules
      plugs/         -- Auth plugs and LiveView hooks
  priv/
    repo/            -- Migrations and seeds
  test/              -- ExUnit tests
docker/
  Dockerfile         -- Elixir 1.17 Alpine image
  docker-compose.yml -- Full development stack
  entrypoint.sh      -- Boot script (deps, migrate, seed, serve)
```

## Default Users

| Email | Password | Role |
|-------|----------|------|
| admin@boilerworks.dev | password1234 | Administrator (all permissions) |

## Default Groups

| Group | Permissions |
|-------|-------------|
| Administrators | All permissions |
| Editors | View + create + edit (products, categories, forms, workflows) |
| Viewers | View-only access |
