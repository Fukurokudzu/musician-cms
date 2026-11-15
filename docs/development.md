# Development setup

This guide covers running `musician-cms` without Docker for local development. For the recommended Docker workflow, see the [README](../README.md) and [DEPLOY.md](../DEPLOY.md).

## Dependencies

Based on the current project configuration:

| Dependency | Version / notes |
|---|---|
| Ruby | 3.4.3 (`.ruby-version` / `.tool-versions`) |
| Bundler | compatible with project gems |
| Node.js | 22.x (`.node-version`, Docker build uses 22.17.1) |
| Yarn | 1.22.x |
| PostgreSQL | 16+ recommended |
| Redis | 7+ recommended |
| ImageMagick and/or libvips | image processing / Active Storage variants |

On Debian/Ubuntu you may need build/system packages such as:
```bash
sudo apt update
sudo apt install -y build-essential libpq-dev libyaml-dev libffi-dev pkg-config imagemagick libvips
```

> Docker and manual setups are different scenarios: the Docker image provides its own runtime dependencies.

## Local setup

1. **Clone and install dependencies**
   ```bash
   git clone git@github.com:Fukurokudzu/musician-cms.git
   cd musician-cms
   bundle install
   yarn install

   # Compiled CSS lives in app/assets/builds and is generated, not committed.
   bin/rails dartsass:build
   ```

2. **Configure services and environment**
   - Start PostgreSQL and Redis locally.
   - Configure database connections for your environment (see `config/database.yml`: dev/test use `DATABASE_DEV_URL` / `DATABASE_TEST_URL`).
   - Configure Redis connection as needed for your environment (`REDIS_URL` / Sidekiq configuration).
   - Set up Rails credentials/master key for the environment you run (Rails standard credentials workflow).

3. **Prepare the database**
   ```bash
   bin/rails db:prepare
   ```

4. **Run the application**
   - Rails server + SCSS watcher: `bin/dev`
   - Or run them separately: `bin/rails server` and `bin/rails dartsass:watch`
     (run `bin/rails dartsass:build` once if you skip the watcher)
   - Sidekiq worker (separate process): `bundle exec sidekiq`

5. **Open the app**
   - Default Rails URL is usually `http://localhost:3000` (unless configured otherwise).
   - Sign in at `/sign_in`. In a fresh/default setup the admin credentials are `admin@admin` / `admin` — change them immediately.

## Notes

- Library scanning and other background work depend on Sidekiq/Redis being available.
- Image uploads/variants depend on image processing libraries being installed.
- Project status is alpha; behavior and setup details may change.
