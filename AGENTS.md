# Project Overview
- Rails 8.1 monolith for the Raspberry Pi Code Editor API (REST + GraphQL), served at `editor-api.raspberrypi.org`.
- Primary runtime via Docker; API listens on port 3009.

## Architecture
- **REST** under `app/controllers/api/**` with Jbuilder views in `app/views/api/**`; **GraphQL** at `/graphql` (schema in `app/graphql/**`).
- **Auth**: Browser/session via OmniAuth (OIDC to Hydra); API token via `Authorization: Bearer` with `Identifiable#identify_user` → `User.from_token` → `HydraPublicApiClient`.
- **Authorization**: cancancan in `app/models/ability.rb`. Use `load_and_authorize_resource` in controllers; GraphQL uses `Types::ProjectType.authorized?` and `current_ability` in context.
- **Domain**: `Project` (+ `Component`) with Active Storage attachments. Controllers and mutations must use an existing domain operation from `lib/concepts/**` (e.g. `Project::Create`, `Project::CreateRemix`). Add a new operation when no suitable one exists; keep logic in the transport layer only when it is transport-specific.
- **Jobs**: GoodJob (`bundle exec good_job start --max-threads=8`). Admin UI at `/admin/good_job`.
- **Integrations**: Profile API (`lib/profile_api_client.rb`), UserInfo API, GitHub GraphQL (`lib/github_api.rb`), GitHub webhooks via `GithubWebhooksController`.
- **Storage/CORS**: Active Storage uses S3 in non-dev. CORS via `config/initializers/cors.rb` and `lib/origin_parser.rb`. `CorpMiddleware` sets CORP for Active Storage routes.

## Sources of Truth
- `.rubocop.yml` is authoritative for machine-checkable Ruby style; do not restate individual cop rules here.
- Specs are authoritative for behavior; add or update specs when behavior changes.
- `AGENTS.md` governs project-specific architectural and workflow decisions.

## Key Conventions
- GraphQL context: `current_user`, `current_ability`, `remix_origin`. Object IDs use GlobalID. Locale fallback via `ProjectLoader`: `[requested, 'en', nil]`.
- REST pagination returns HTTP `Link` header (see `Api::ProjectsController#pagination_link_header`).
- Project rules: identifiers unique per locale; default component name/extension immutable on update; students cannot update `instructions` on school projects; creating a project in a school auto-builds `SchoolProject`.
- Remix: `Project::CreateRemix` clones media/components, sets `remix_origin`, clears `lesson_id`.
- Errors: domain ops return `OperationResponse` with `:error`; controllers return 4xx heads; GraphQL raises `GraphQL::ExecutionError`. Exceptions reported to Sentry.

## Quickstart
```bash
cp .env.example .env
docker compose build
docker compose run --rm api rails db:setup
docker compose up
```

## Development
- Use `docker compose` for all commands; project mounts into `editor-api:builder` with tmpfs for `tmp/`.

## Testing
- After changing behavior, run the closest relevant spec: `docker compose run --rm api rspec spec/path/to/spec.rb`
- After changing Ruby, run RuboCop: `docker compose run --rm api bundle exec rubocop`
- After changing shared infrastructure, the database or schema, authorization, or other cross-cutting behavior, run the full suite: `docker compose run --rm api rspec`
- CI: GitHub Actions with Ruby 4, Postgres 12, Redis.
- Salesforce sync specs need `SALESFORCE_CONNECT_DB` set and matching Heroku Connect tables (schema comes from the published `heroku-connect` image after Salesforce mapping is exported).

## Salesforce / Heroku Connect
- Sync writes to the `salesforce_connect` DB (not a Salesforce API). Pattern from editor-api PR #677.
- Feature flag: `SALESFORCE_ENABLED=true`.
- After deploy, backfill: `rails salesforce_sync:school`, `salesforce_sync:role`, `salesforce_sync:contact`, `salesforce_sync:school_class`, `salesforce_sync:class_teacher`, `salesforce_sync:lesson`.
- **Parent-sync race guard (required for any job using `__r__` external-ID lookups).** Heroku Connect rejects an INSERT permanently with `Foreign key external ID … not found` if the parent record isn't yet in Salesforce — the mirror row stays `FAILED` forever (no auto-retry). Call `ensure_parent_synced!(model, external_id_field, external_id, label)` on `Salesforce::SalesforceSyncJob` (the base class) before saving a child record; it checks the parent has a non-nil `sfid` in its Heroku Connect mirror and raises `SalesforceRecordNotFound` if not. The base job declares `retry_on SalesforceRecordNotFound, wait: :polynomially_longer, attempts: 10` so the job self-heals once parents land. See `Salesforce::RoleSyncJob` and `Salesforce::ClassTeacherSyncJob` for call-site examples.

## Where to Look First
- Routes: `config/routes.rb`. Auth: `config/initializers/omniauth.rb`, `app/helpers/authentication_helper.rb`, `app/controllers/concerns/identifiable.rb`.
- Permissions: `app/models/ability.rb`. Domain ops: `lib/concepts/**`. Models: `app/models/**`. GraphQL: `app/graphql/**`.

## Security
- Never commit secrets (`.env`, `config/master.key`, API tokens, webhook secrets).
- `.env.example` contains placeholder values only.
