# Project Overview
- Rails 7.1 monolith for the Raspberry Pi Code Editor API (REST + GraphQL), served at `editor-api.raspberrypi.org`.
- Primary runtime via Docker; API listens on port 3009.

## Architecture
- **REST** under `app/controllers/api/**` with Jbuilder views in `app/views/api/**`; **GraphQL** at `/graphql` (schema in `app/graphql/**`).
- **Auth**: Browser/session via OmniAuth (OIDC to Hydra); API token via `Authorization: Bearer` with `Identifiable#identify_user` → `User.from_token` → `HydraPublicApiClient`.
- **Authorization**: cancancan in `app/models/ability.rb`. Use `load_and_authorize_resource` in controllers; GraphQL uses `Types::ProjectType.authorized?` and `current_ability` in context.
- **Domain**: `Project` (+ `Component`) with Active Storage attachments. Domain operations in `lib/concepts/**` (e.g. `Project::Create`, `Project::CreateRemix`). Prefer calling these from controllers/mutations.
- **Jobs**: GoodJob (`bundle exec good_job start --max-threads=8`). Admin UI at `/admin/good_job`.
- **Integrations**: Profile API (`lib/profile_api_client.rb`), UserInfo API, GitHub GraphQL (`lib/github_api.rb`), GitHub webhooks via `GithubWebhooksController`.
- **Storage/CORS**: Active Storage uses S3 in non-dev. CORS via `config/initializers/cors.rb` and `lib/origin_parser.rb`. `CorpMiddleware` sets CORP for Active Storage routes.

## Key Conventions
- GraphQL context: `current_user`, `current_ability`, `remix_origin`. Object IDs use GlobalID. Locale fallback via `ProjectLoader`: `[requested, 'en', nil]`.
- REST pagination returns HTTP `Link` header (see `Api::ProjectsController#pagination_link_header`).
- Project rules: identifiers unique per locale; default component name/extension immutable on update; students cannot update `instructions` on school projects; creating a project in a school auto-builds `SchoolProject`.
- Remix: `Project::CreateRemix` clones media/components, sets `remix_origin`, clears `lesson_id`.
- Errors: domain ops return `OperationResponse` with `:error`; controllers return 4xx heads; GraphQL raises `GraphQL::ExecutionError`. Exceptions reported to Sentry.
- snake_case for variable numbers (exceptions: `sha256`, `X-Hub-Signature-256`).

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
- Full suite: `docker compose run --rm api rspec`
- Single spec: `docker compose run --rm api rspec spec/path/to/spec.rb`
- Lint: `docker compose run --rm api bundle exec rubocop`
- CI: GitHub Actions with Ruby 3.4, Postgres 12, Redis.

## Where to Look First
- Routes: `config/routes.rb`. Auth: `config/initializers/omniauth.rb`, `app/helpers/authentication_helper.rb`, `app/controllers/concerns/identifiable.rb`.
- Permissions: `app/models/ability.rb`. Domain ops: `lib/concepts/**`. Models: `app/models/**`. GraphQL: `app/graphql/**`.

## Security
- Never commit secrets (`.env`, `config/master.key`, API tokens, webhook secrets).
- `.env.example` contains placeholder values only.
