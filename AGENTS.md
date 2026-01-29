# Project Overview
- Rails 7.1 monolith for the Raspberry Pi Code Editor API (REST + GraphQL), served at
  `editor-api.raspberrypi.org`. Provides auth, project storage, and education features.
- Primary runtime via Docker; API listens on port 3009 in containers.

## Repository Structure
- `app/` Rails application code (REST, GraphQL, jobs, views, admin).
- `config/` environment, initializers, Puma, CORS, credentials.
- `db/` migrations, seeds, schema helpers; `bin/db-sync/` for pulling Heroku data locally.
- `spec/` RSpec tests (Rails, GraphQL, feature/system).
- `bin/` developer scripts (`with-builder.sh`, `db-sync/*`, Rails binstubs).
- `lib/` supporting libraries, tasks, assets; `public/` static assets; `docker-compose.yml`
  for local stack; `.circleci/` for CI; `.rubocop.yml` for style config.

## Quickstart Commands
```bash
cp .env.example .env
docker-compose build
docker compose run --rm api rails db:setup
docker-compose up
# API available on http://localhost:3009
```

## Development Workflow
- Prefer Docker compose; mounts project into `editor-api:builder` image with tmpfs for `tmp/`.
- Use `./bin/with-builder.sh <cmd>` for operations that modify Gemfile.lock (e.g. `bundle update`).
- Seeds (dev): `docker compose run --rm api rails projects:create_all` and
  `docker compose run --rm api rails for_education:seed_a_school_with_lessons_and_students`
  (others in README).
- DB sync (needs Heroku access): `./bin/db-sync/production-to-local.sh` or `staging-to-local.sh`.
- Background jobs use GoodJob; Procfile defines `worker: bundle exec good_job start --max-threads=8`.

## Testing & CI
- Full suite: `docker-compose run api rspec`
- Single spec: `docker-compose run api rspec spec/path/to/spec.rb`
- CI (CircleCI): Ruby 3.2 images with Postgres 12 + Redis; steps include `bin/rails db:setup --trace`,
  `ruby/rspec-test`, RuboCop via `ruby/rubocop-check`, coverage artifacts uploaded and posted via
  `.circleci/record_coverage`.

## Code Style & Conventions
- Ruby `~> 3.2.0`.
- RuboCop uses Raspberry Pi Foundation shared configs plus Rails/RSpec/GraphQL cops; many metrics and
  line-length checks are relaxed.
- Variable numbers must be snake_case (allowed: `sha256`, `X-Hub-Signature-256`).
- Tests in RSpec (`spec/`), Jbuilder for JSON views, GraphQL types under `app/graphql/`.
- GoodJob for background processing; Puma configured via `config/puma.rb`; release hook runs migrations
  then `rake projects:create_experience_cs_examples` (see Procfile).

## Security & Safety Guardrails
- Never commit secrets: `.env`, `config/master.key`, AWS/Postmark tokens, Hydra/Profile secrets,
  webhook secrets. Keep `.env.example` values as references only.
- DB sync scripts fetch production/staging data; run only if authorized and handle dumps securely.
- Generated/ignored paths: `log/`, `tmp/`, `storage/`, `coverage/`, `public/assets/`, `.bundle/`,
  `docker-compose.override.yml` (gitignored); do not add noise from these.
- Webhooks and smee tunnel secrets live in env vars; avoid logging or sharing real values.

## Common Tasks (add feature, add test, refactor, release/deploy if applicable)
- Run app locally: ensure `.env`, then `docker-compose up` (build + `rails db:setup` first).
- Lint: `docker-compose run --rm api bundle exec rubocop` (mirrors CI RuboCop check).
- Migrate: `docker compose run --rm api rails db:migrate` (release hook also migrates).
- Update gems: `./bin/with-builder.sh bundle update` (keeps builder image and lockfiles in sync).
- Seed dev data: commands in README (e.g. `rails projects:create_all`,
  `rails for_education:seed_a_school_with_lessons_and_students`).
- Sync DB from Heroku: `./bin/db-sync/production-to-local.sh` or `staging-to-local.sh` (requires Heroku
  CLI + app access).
- Release/deploy: Procfile release runs migrations then `rake projects:create_experience_cs_examples`;
  confirm platform/trigger before running manually. > TODO: document official deploy pipeline and branch
  triggers.

## Further Reading (relative links)
- `README.md`
- `.circleci/config.yml`
- `.rubocop.yml`
- `.env.example`
- `Procfile`
- `bin/db-sync/load-local-db.sh`
