# Deployment Guide

## Quick start with Docker Compose

1. Copy the example env file and adjust if needed:
   ```bash
   cp .env.example .env
   ```

2. Build and start the stack:
   ```bash
   docker compose up -d --build
   ```

The entrypoint will automatically generate credentials and set up the database on first run.

## Persistent volumes

- `postgres_data` - PostgreSQL data
- `storage_data` - Active Storage uploads/covers/tracks
- `music_library` - Mounted music library (or bind mount a host path)
- `credentials_data` / `master_key_data` - Rails credentials persistence

No manual `chown` is needed for the volumes: the entrypoint starts as root,
fixes ownership of `log`, `storage`, `app/music` and `config/credentials` if
they were created by an older (root) image, then drops all privileges to the
unprivileged `rails` user before running any application code.

The container user IDs default to `1000:1000` and can be overridden at build
time via the `UID`/`GID` build arguments (picked up from your shell
environment by docker compose).

## Build caching

Builds rely on the local BuildKit cache — do **not** run `docker builder
prune` / `docker system prune` on the deploy host, otherwise every deploy
rebuilds gems, node modules and assets from scratch.

What is cached:

- gem installation: kept in a BuildKit cache mount, so a `Gemfile.lock`
  change reinstalls gems without recompiling native extensions
  (and no `gem_cache` volume is needed — it was a runtime mount and never
  affected build time);
- everything up to `COPY . .` (apt packages, node/yarn, bundle): invalidated
  only when the corresponding files change — editor files, specs, docs and
  generated credentials are excluded via `.dockerignore`, so routine code
  edits rebuild only bootsnap/assets and the final stage.

## Music library

By default the compose file mounts `music_library` volume to `/rails/app/music`. You can either:
- Copy files into the named volume
- Replace with a bind mount: `- /path/to/your/music:/rails/app/music:ro` (read-only recommended)

The library path in settings defaults to `app/music` and is configurable from the admin UI.

## Credentials

If you want to provide your own master key, set `RAILS_MASTER_KEY` in `.env`. Otherwise a new key and credentials are generated on boot.

## Running without Docker

See README or standard Rails setup: configure DB/Redis, set env vars, run migrations, start web and Sidekiq.
