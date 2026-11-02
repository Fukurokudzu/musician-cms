# syntax=docker/dockerfile:1
# check=error=true

ARG RUBY_VERSION=3.4.3
FROM ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Update gems and bundler
RUN gem update --system --no-document && \
    gem install -N bundler

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 postgresql-client imagemagick && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set default environment (can be overridden at runtime)
ENV BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems and node modules
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential libffi-dev libpq-dev libyaml-dev node-gyp pkg-config python-is-python3 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install JavaScript dependencies
ARG NODE_VERSION=22.17.1
ARG YARN_VERSION=1.22.19
ENV PATH=/usr/local/node/bin:$PATH
RUN curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \
    /tmp/node-build-master/bin/node-build "${NODE_VERSION}" /usr/local/node && \
    npm install -g yarn@$YARN_VERSION && \
    rm -rf /tmp/node-build-master

# Install application gems.
# The BuildKit cache mount keeps the compiled gems between builds, so a
# Gemfile.lock change does not recompile native extensions (pg, nokogiri,
# ...) from scratch. Cache mounts are not part of the image, so the result
# is copied out into a regular directory that later steps and the final
# stage can see.
COPY Gemfile Gemfile.lock ./
RUN --mount=type=cache,target=/bundle-cache \
    BUNDLE_PATH=/bundle-cache bundle install && \
    rm -rf ~/.bundle/ /bundle-cache/ruby/*/cache /bundle-cache/ruby/*/bundler/gems/*/.git && \
    BUNDLE_PATH=/bundle-cache bundle exec bootsnap precompile --gemfile && \
    mkdir -p /gems && cp -a /bundle-cache/. /gems/
ENV BUNDLE_PATH=/gems

# Install node modules
COPY .yarnrc package.json package-lock.json yarn.lock ./
COPY .yarn/releases/* .yarn/releases/
RUN yarn install --frozen-lockfile

# Copy application code
COPY . .

# Any existing credential files to avoid permission issues might be removed
RUN rm -f config/master.key config/credentials.yml.enc config/credentials/production.key config/credentials/production.yml.enc config/credentials/development.key config/credentials/development.yml.enc config/credentials/test.key config/credentials/test.yml.enc 2>/dev/null || true

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Adjust binfiles to be executable on Linux
RUN sed -i "s/\r$//g" bin/* && \
    sed -i 's/ruby\r$/ruby/' bin/* && \
    chmod +x bin/*

# Precompile assets
RUN SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production ./bin/rails assets:precompile

# Ensure assets are properly served
RUN ./bin/rails assets:clean

# Final stage for app image
FROM base

# Create the unprivileged app user first so every copied file can get the
# right owner in a single pass — no recursive chown during the build.
ARG UID=1000
ARG GID=1000

RUN set -eux; \
    groupadd -f -g "${GID}" rails; \
    useradd -u "${UID}" -g "${GID}" rails --create-home --shell /bin/bash

# Copy built artifacts: gems, application.
# The gems were copied out of the BuildKit cache mount in the build stage
# (see above) and now live in /gems there.
COPY --from=build --chown=rails:rails /gems /usr/local/bundle
COPY --from=build --chown=rails:rails /rails /rails

COPY --chown=rails:rails --chmod=755 bin/docker-entrypoint /rails/bin/

# The container starts as root so the entrypoint can fix ownership of
# mounted volumes, then drops privileges to the unprivileged `rails` user
# before running any application code.

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["./bin/rails", "server"]
