#!/bin/sh
set -e

echo "==> Installing dependencies..."
mix deps.get
mix deps.compile

echo "==> Installing npm dependencies..."
cd assets && npm install && cd ..

echo "==> Setting up assets..."
mix assets.setup 2>/dev/null || true
mix assets.build 2>/dev/null || true

echo "==> Creating database..."
mix ecto.create 2>/dev/null || true

echo "==> Running migrations..."
mix ecto.migrate

echo "==> Seeding database..."
mix run priv/repo/seeds.exs 2>/dev/null || true

echo "==> Starting Phoenix server..."
exec mix phx.server
