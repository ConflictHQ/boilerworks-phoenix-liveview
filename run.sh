#!/usr/bin/env bash
set -euo pipefail

# Boilerworks — Phoenix LiveView
# Usage: ./run.sh [command]

COMPOSE_FILE=""

if [ -f "docker-compose.yml" ]; then
    COMPOSE_FILE="docker-compose.yml"
elif [ -f "docker-compose.yaml" ]; then
    COMPOSE_FILE="docker-compose.yaml"
elif [ -f "docker/docker-compose.yml" ]; then
    COMPOSE_FILE="docker/docker-compose.yml"
elif [ -f "docker/docker-compose.yaml" ]; then
    COMPOSE_FILE="docker/docker-compose.yaml"
fi

compose() {
    if [ -n "$COMPOSE_FILE" ]; then
        docker compose -f "$COMPOSE_FILE" "$@"
    else
        echo "No docker-compose file found"
        exit 1
    fi
}

case "${1:-help}" in
    up|start)
        compose up -d --build
        echo "Waiting for services..."
        sleep 5
        compose exec -T app mix ecto.migrate 2>&1 | tail -3
        echo ""
        echo "Services running. Check status with: ./run.sh status"
        ;;
    down|stop)
        compose down
        ;;
    restart)
        compose down
        compose up -d --build
        ;;
    status|ps)
        compose ps
        ;;
    logs)
        compose logs -f "${2:-}"
        ;;
    seed)
        compose exec -T app mix ecto.migrate
        compose exec app mix run priv/repo/seeds.exs
        ;;
    test)
        compose exec app mix test
        ;;
    lint)
        compose exec app mix format --check-formatted && compose exec app mix credo
        ;;
    shell)
        compose exec app iex -S mix
        ;;
    migrate)
        compose exec app mix ecto.migrate
        ;;
    help|*)
        echo "Usage: ./run.sh <command>"
        echo ""
        echo "Commands:"
        echo "  up, start     Start all services"
        echo "  down, stop    Stop all services"
        echo "  restart       Restart all services"
        echo "  status, ps    Show service status"
        echo "  logs [svc]    Tail logs (optionally for one service)"
        echo "  seed          Seed the database"
        echo "  test          Run tests"
        echo "  lint          Run linters"
        echo "  shell         Open an IEx console"
        echo "  migrate       Run Ecto migrations"
        echo "  help          Show this help"
        ;;
esac
