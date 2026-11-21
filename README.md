# musician-cms

A simple self-hosted Ruby on Rails CMS for musician portfolios — publish releases, stream tracks and customize the look, all from a built-in admin panel.

<p align="center">
  <img src="docs/images/main.png" alt="musician-cms — main page" width="820">
</p>

<p align="center">
  <img src="docs/images/admin.png" alt="musician-cms — admin panel" width="820">
</p>

## ⚠️ Status: Alpha

This project is in active development. Expect breaking changes, incomplete features and rough edges. Do not use it in production without reviewing the code and keeping backups.

## What it does

`musician-cms` is aimed at musicians who want a small personal music site: an artist page with releases, cover art, a persistent audio player, a small markdown blog and a lightweight admin panel for uploading music. No accounts for visitors, no comments, no bloat — just a clean portfolio site you can host yourself.

## Features

- **Public site**
  - Artist pages with release grids grouped by year
  - Release pages with tracklists, cover art and optional ZIP downloads
  - Built-in audio player that persists across page navigation (Turbo)
  - Random "now playing" track when you first arrive
  - Blog at `/blog` — markdown posts managed from the admin panel; the header link appears once at least one post exists
  - Fresh installs show a welcome screen instead of a blank page until the first release is published
  - 404/500 error pages rendered through the site layout (not static HTML)
- **Admin panel**
  - Upload releases: audio files, cover art, titles, dates and statuses (draft/published/archived); uploaded tracks inherit the release status
  - Manage artists, tracks, play counts and library paths
  - Scan a local music folder and import new releases automatically (Sidekiq job)
  - Blog: create, edit and soft-delete markdown posts (GFM, rendered and sanitized server-side)
  - Theme editor: colors, background image, favicon and corner radius — live CSS variables, no code changes needed
  - Configurable site title, description, locale (EN/RU/ES/FR/DE, also switchable via `?locale=` or `?lang=`), date format and footer contact link (email or URL)
  - Logs: audit trail of admin actions with category filters and configurable retention (default 90 days), plus download/truncate of the raw application log
  - Statistics: plays and downloads per release/track, daily activity graph, sortable tables, per-country breakdown (GeoIP)
  - About: build diagnostics — branch/commit/source (from a git tag, CI environment or the container build args)
- **Under the hood**
  - Ruby on Rails 8.1, Hotwire (Turbo + Stimulus)
  - PostgreSQL, Redis + Sidekiq for background jobs
  - Active Storage for covers and audio
  - Fully containerized: one `docker compose up` brings up web, database, Redis and workers

### Release statuses

- **Draft** — visible only in the admin panel; not shown on the public site and not accessible by direct URL.
- **Published** — visible publicly (listings, release page, player, ZIP download when enabled).
- **Archived** — removed from the public site (hidden from listings, not accessible by direct URL, not playable/downloadable), but kept in the admin panel with all data and can be restored by changing status (e.g. back to draft or published).

## Installation (Docker)

### Requirements

- Docker Engine with BuildKit
- Docker Compose v2

### Quick start

```bash
git clone git@github.com:Fukurokudzu/musician-cms.git
cd musician-cms
cp .env.example .env
./bin/prod-deploy
```

The helper runs `docker compose up -d --build` and automatically fills in
`GIT_COMMIT`/`GIT_BRANCH` from the current checkout (used by the *Admin → About*
diagnostics). When the checkout is exactly on a git tag (e.g. after
`git checkout v1.2.3`), the tag name is used as the commit; otherwise the short
commit hash is used. Any extra arguments are forwarded to Compose, e.g.
`./bin/prod-deploy --build`.

If you prefer, the plain Compose command works too:

```bash
docker compose up -d --build
```

That's it. On first run the entrypoint generates Rails credentials and prepares the database automatically. See [DEPLOY.md](DEPLOY.md) for deployment details.

The web app will be available at `http://localhost:3003` (the port is mapped to `127.0.0.1`, put your reverse proxy in front for HTTPS).

### First login

1. Go to `http://localhost:3003/sign_in`
2. Sign in with the default credentials: **admin@admin / admin**
3. **Change the password immediately** in the *System* tab of the admin panel

Until the first release is published, visitors to `/` see a welcome screen pointing to the sign-in page instead of an empty page.

### Music library

By default the compose file mounts a named volume to `/rails/app/music`. You can either copy files into the volume or replace it with a bind mount in `docker-compose.yml`:

```yaml
volumes:
  - /path/to/your/music:/rails/app/music:ro
```

Then use the *Library* tab in the admin panel to check the library path and run a scan — releases and tracks found in the folder are imported for you.

### Statistics

The *Statistics* tab in the admin panel shows plays by release (chart), sortable per-track and per-download tables, a daily activity graph and a per-country breakdown of plays and downloads. All figures, including "all time" totals, are derived from recorded play/download events.

Country detection uses the free [DB-IP Lite](https://db-ip.com/dbip-lite.html) database (about 8 MB, no account or key required). The image no longer downloads it at build time (that used to stall deploys when db-ip.com was slow/unreachable); instead, on first boot with an empty volume the container entrypoint attempts a best-effort, non-blocking background download, and `bin/rails geoip:update` is available for an immediate manual refresh. DB-IP publishes a new database monthly, so a manual refresh (or a fresh download) picks up the latest one. Visitors' IPs are never stored — only a one-way HMAC hash (for unique-listener counts) and the resolved country.

Statistics can also be downloaded as a report: the *Export* section at the bottom of the Statistics tab generates a full CSV or XLSX (summary, daily activity, all tracks and all releases with statuses, creation dates and play/download totals, plus the per-country table) in a Sidekiq job and shows a progress bar while it builds. Generated reports stay downloadable for 24 hours.

### Volumes

| Volume | Purpose |
|---|---|
| `postgres_data` | PostgreSQL data |
| `storage_data` | Active Storage uploads (covers, audio) |
| `music_library` | Mounted music library (or bind mount a host path) |
| `credentials_data` | Rails credentials persistence |

## Documentation

- [DEPLOY.md](DEPLOY.md) — deployment details: volumes, build caching, credentials, the music library and the admin Logs tab

## Contributing

Contributions are welcome via pull requests (PR):

1. Fork the repository and branch off `dev`.
2. Make your changes and cover them with specs — the suite must stay green
   (`bundle exec rspec`); run rubocop for Ruby changes.
3. Open an PR against `dev` describing the problem and the fix. Small, focused
   PRs are easier to review.

For local setup, see [docs/development.md](docs/development.md).

### Translations

To add a language, add `config/locales/<lang>.yml` with keys matching `en.yml`
one-to-one (plus `date.month_names` for `%B` rendering), then register it in
`config/application.rb` (`available_locales`), `app/models/setting.rb`
(`locale` `option_values`) and `locale_options`
(`app/helpers/application_helper.rb`). If the language has non-trivial plural
forms, add CLDR rules to `config/locales/plural_rules.rb`.

## Live example

[music.fukurokudzu.ru](https://music.fukurokudzu.ru) — the site in the screenshot above.
