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
- `gem_cache` - Bundler cache

## Music library

By default the compose file mounts `music_library` volume to `/rails/app/music`. You can either:
- Copy files into the named volume
- Replace with a bind mount: `- /path/to/your/music:/rails/app/music:ro` (read-only recommended)

The library path in settings defaults to `app/music` and is configurable from the admin UI.

## Credentials

If you want to provide your own master key, set `RAILS_MASTER_KEY` in `.env`. Otherwise a new key and credentials are generated on boot.

## Running without Docker

See README or standard Rails setup: configure DB/Redis, set env vars, run migrations, start web and Sidekiq.
