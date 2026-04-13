FROM elixir:1.19-alpine AS base

RUN apk add --no-cache build-base git nodejs npm inotify-tools postgresql-client curl

ENV MIX_ENV=dev
ENV HEX_HTTP_TIMEOUT=120

RUN mix local.hex --force && mix local.rebar --force

WORKDIR /app

# Copy mix files first for dependency caching
COPY app/mix.exs ./
RUN touch mix.lock

# Get and compile deps
RUN mix deps.get && mix deps.compile

# Install npm deps for tailwind forms plugin
COPY app/assets/package.json assets/package.json
RUN cd assets && npm install

# Copy the rest of the application
COPY app/ ./

# Setup assets (install esbuild + tailwind binaries)
RUN mix assets.setup 2>/dev/null || true

EXPOSE 4000

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
