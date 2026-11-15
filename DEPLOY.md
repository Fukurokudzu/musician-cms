# Deployment Guide

This document covers deployment details for `musician-cms` with Docker Compose.

## Quick start

1. Copy the example env file and adjust if needed:
   ```bash
   cp .env.example .env
   ```

2. Build and start the stack:
   ```bash
   ./bin/prod-deploy
   ```

   The helper runs `docker compose up -d --build` and automatically fills in
   `GIT_COMMIT`/`GIT_BRANCH` from the current checkout. Any extra arguments are
   forwarded to Compose, e.g. `./bin/prod-deploy --build`.

   If you prefer, the plain Compose command works too:
   ```bash
   docker compose up -d --build
   ```

3. Check status and logs:
   ```bash
   docker compose ps
   docker compose logs -f web sidekiq
   ```

On first boot the entrypoint:
- fixes ownership of mounted runtime directories when needed,
- prepares Rails credentials (or uses existing/persisted ones),
- runs `bin/rails db:prepare`,
- starts the requested process as the unprivileged `rails` user.

The web app is bound to `127.0.0.1:3003` by default. Put a reverse proxy (Nginx, Caddy, Traefik, etc.) in front for TLS/public access.

## Deploy helper script (`bin/prod-deploy`)

The repository ships a small wrapper, `bin/prod-deploy`, that performs a
standard production deploy in one step:

```bash
./bin/prod-deploy
```

What it does:

- resolves `GIT_COMMIT` and `GIT_BRANCH` from the current git checkout
  (when run inside a git work tree) and exports them, so the **Admin → About**
  diagnostics show the deployed revision without editing `.env`;
- uses the current tag as `GIT_COMMIT` when the checkout is exactly on a git
  tag (e.g. after `git checkout v1.2.3`), otherwise falls back to the short
  commit hash (`git rev-parse --short HEAD`);
- falls back to any pre-existing `GIT_COMMIT`/`GIT_BRANCH`/`REVISION`/`BRANCH`
  values when git metadata is unavailable (for example, when deploying from a
  tarball);
- runs `docker compose up -d --build`, forwarding any extra arguments to
  Compose, e.g. `./bin/prod-deploy web` or `./bin/prod-deploy --build`.

The script is executable and locates the project root from its own location, so
it can be invoked from anywhere. It is the recommended entry point for updates
on a deploy host; the manual `git pull && docker compose up -d --build` flow
remains supported.

## Environment variables (`.env`)

`docker-compose.yml` reads optional values from `.env`:

| Variable | Purpose | Default |
|---|---|---|
| `UID` | Build-time container user ID (affects image/build args) | `1000` |
| `GID` | Build-time container group ID | `1000` (or `UID`) |
| `GIT_COMMIT` | Optional commit shown in **Admin → About** diagnostics (build arg + runtime env) | empty |
| `GIT_BRANCH` | Optional branch shown in **Admin → About** diagnostics (build arg + runtime env) | empty |

Runtime service configuration such as `DATABASE_URL`, `REDIS_URL`, and `RAILS_ENV` is currently defined directly in `docker-compose.yml`.

Because `.git` is excluded from the Docker build context, branch/commit cannot be auto-detected during image build. Pass them when building:

```bash
GIT_COMMIT=$(git describe --tags --exact-match 2>/dev/null || git rev-parse --short HEAD) \
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD) \
docker compose up -d --build
```

Alternatively set `GIT_COMMIT`/`GIT_BRANCH` in `.env` before building, or provide them as runtime environment variables (diagnostics also read env vars). If the image was already built without these values, rebuild the image to bake them into `REVISION`/`BRANCH` files (or set runtime env vars and restart).

## Credentials

- Rails credentials/key files are persisted in the `credentials_data` volume (mounted at `/rails/config/credentials`).
- Web and Sidekiq share this volume and use a lock to avoid concurrent credential generation.
- On boot, the entrypoint reuses existing credentials/key files from the volume; if they are missing, it generates a new key and fresh credentials (including `secret_key_base`).

**Important:** back up the `credentials_data` volume. Losing it together with encrypted credentials can make existing credentials unrecoverable.

## Persistent volumes

| Volume | Mount / purpose |
|---|---|
| `postgres_data` | PostgreSQL data (`/var/lib/postgresql/data`) |
| `storage_data` | Active Storage uploads/covers/audio (`/rails/storage`) |
| `music_library` | Music library path (`/rails/app/music`) |
| `credentials_data` | Rails credentials and key files (`/rails/config/credentials`) |

`./log` is also bind-mounted to `/rails/log` for easier access to logs on the host.

`docker compose down` keeps volumes. `docker compose down -v` removes named volumes and **will delete data**.

## Music library

By default the compose file mounts the `music_library` volume to `/rails/app/music`.
You can either:
- copy files into the named volume, or
- replace it with a bind mount, for example: `- /path/to/your/music:/rails/app/music:ro` (read-only is fine/recommended for a scan source).

Do not edit `docker-compose.yml` on the deploy host to switch to a bind mount: it is a tracked file and every `git pull` will conflict. Put host-specific paths in a git-ignored `docker-compose.override.yml` instead. Compose v2 merges it automatically, and volume entries are matched by the container path, so this replaces the `music_library` mount for both app services:

```yaml
services:
  web:
    volumes:
      - /srv/music:/rails/app/music:ro
  sidekiq:
    volumes:
      - /srv/music:/rails/app/music:ro
```

Check the result with `docker compose config` (expect `bind` + `read_only: true` for `/rails/app/music` in both services).

The library path defaults to `app/music` in application settings and can be reviewed/used from the admin panel (Library tab / scan).

The library path is a **source directory for scanning/import**: the scan job reads audio/cover files from it and attaches copies to Active Storage. It does not need write access, so `:ro` is appropriate for an external collection. Releases uploaded through the admin UI are stored in Active Storage (`storage_data`), not written into the music library folder. Use a writable mount only if other container-side processes must modify files there.

## Build caching

Builds rely on the local BuildKit cache. Avoid running `docker builder prune` / `docker system prune` on the deploy host unless necessary, as it can force full rebuilds (gems, node modules, assets).

Cached behavior (high level):
- gem installation uses a BuildKit cache mount (faster rebuilds when `Gemfile.lock` changes);
- layers before `COPY . .` are reused when their inputs do not change (`.dockerignore` excludes docs/specs/editor files, etc.).

Optional build args for revision metadata (used in diagnostics/About): `GIT_COMMIT`, `GIT_BRANCH`.
Example:
```bash
GIT_COMMIT=$(git describe --tags --exact-match 2>/dev/null || git rev-parse --short HEAD) \
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD) \
docker compose build
```

## Updates

Typical update flow:
```bash
git pull
docker compose up -d --build
```

Or, using the deploy helper (also records the deployed revision):
```bash
git pull
./bin/prod-deploy
```

The entrypoint runs `db:prepare` on startup, so pending migrations are applied automatically. Always keep backups before updating.

## Troubleshooting

- **Check service status:** `docker compose ps`
- **Follow logs:** `docker compose logs -f web sidekiq postgres-db redis-db`
- **Database not ready / connection errors:** wait for `postgres-db` healthcheck, then inspect DB logs.
- **App not reachable:** confirm port mapping `127.0.0.1:3003->3000`, container health/logs, and reverse-proxy config.
- **Stale build issues after dependency changes:** rebuild with `docker compose build --no-cache` (slower, but clean).

## Backup and restore

Back up persistent data before updates or host changes:

- **PostgreSQL (`postgres_data`)**: use `pg_dump`/`pg_restore` (or volume snapshots) appropriate for your environment.
- **Active Storage files (`storage_data`)**: uploaded covers/audio and stored files.
- **Credentials (`credentials_data`)**: Rails key/credentials files required to decrypt credentials.
- **Music library (`music_library` or bind mount)**: source files, if managed as data you care about.
- **Logs (`./log`)**: optional.

`docker compose down -v` removes named volumes and causes data loss. Restores should be tested and performed with the stack stopped as appropriate.

## Running without Docker

See [docs/development.md](docs/development.md) for local/manual development setup. For non-Docker deployments you must provide PostgreSQL, Redis, required environment configuration, run migrations, and run both the Rails web process and Sidekiq worker.
