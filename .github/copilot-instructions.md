# Copilot instructions for editor-api

This repo is a Rails 7.1 exposing REST and GraphQL APIs for the Raspberry Pi Foundation Code Editor and Code Editor for Education features.

Architecture and boundaries
- HTTP surfaces: REST under `app/controllers/api/**` (responses via jbuilder in `app/views/api/**`) and GraphQL at `/graphql` (schema in `app/graphql/**`).
- Authentication: Browser/session via OmniAuth (OIDC to Hydra) in `config/initializers/omniauth.rb` and `AuthController`; API token via `Authorization: Bearer <token>` with lookup in `Identifiable#identify_user` → `User.from_token` → `HydraPublicApiClient`.
- Authorization: `cancancan` in `app/models/ability.rb`. Permissions differ for students/teachers/owners/admin. Use `load_and_authorize_resource` in controllers and `Types::ProjectType.authorized?` plus `GraphqlController` context `current_ability` for GraphQL.
- Domain: `Project` (+ `Component`) with attachments (`images/videos/audio` via Active Storage). Higher-level operations live under `lib/concepts/**` (e.g., `Project::Create`, `Project::Update`, `Project::CreateRemix`). Prefer calling these from controllers/mutations.
- Jobs: GoodJob (`config/initializers/good_job.rb`, Procfile `worker`). Admin UI is mounted at `/admin/good_job` and gated by `AuthenticationHelper#current_user.admin?`.
- Integrations: Profile API (`lib/profile_api_client.rb`) for schools/students and safeguarding flags; UserInfo API for user detail fan-out; GitHub GraphQL client in `lib/github_api.rb`; GitHub webhooks via `GithubWebhooksController` trigger `UploadJob` when `ref == ENV['GITHUB_WEBHOOK_REF']` and files under `*/code/` change.
- Storage/CORS: Active Storage uses S3 in non-dev; `config/initializers/cors.rb` and `lib/origin_parser.rb` parse `ALLOWED_ORIGINS`. `CorpMiddleware` sets CORP for Active Storage routes.

Key conventions and patterns
- GraphQL context includes: `current_user`, `current_ability`, and `remix_origin` (see `GraphqlController`). Max depth/complexity guard rails in `EditorApiSchema`.
- GraphQL object IDs use GlobalID; locale fallback for projects via `ProjectLoader` in order `[requested, 'en', nil]`.
- Jbuilder responses: see `app/views/api/projects/show.json.jbuilder` for shape (components, media URLs via `rails_blob_url`, optional `parent`).
- Pagination for REST lists returns HTTP `Link` header (see `Api::ProjectsController#pagination_link_header`).
- Project rules: identifiers unique per locale; default component’s name/extension immutable on update; students cannot update `instructions` on school projects; creating a project within a school auto-builds a `SchoolProject`.
- Remix: `Project::CreateRemix` clones media/components, sets `remix_origin` from `request.origin` and clears `lesson_id`.
- Errors: domain ops return `OperationResponse` with `:error`; controllers return 4xx heads for common cases; GraphQL raises `GraphQL::ExecutionError`. Exceptions are reported to Sentry.

Developer workflows (docker-first)
- Setup: copy `.env.example` → `.env`. Build with `docker-compose build`. Prepare DB: `docker compose run --rm api rails db:setup`.
- Run: `docker-compose up` (API on http://localhost:3009). GraphiQL available in non-production at `/graphql`.
- Tests: `docker-compose run api rspec` (or pass a spec path). Bullet, WebMock, and RSpec rails are configured in `spec/rails_helper.rb`.
- Seeds: run `projects:create_all` and `for_education:*` Rake tasks (examples in README). Experience CS examples auto-run on release (see Procfile `release`).
- DB sync: scripts in `bin/db-sync/*` pull Heroku backups into your local Docker DB and reset Active Storage to `local`.
- Gems: update inside the builder image with `./bin/with-builder.sh bundle update`.

Important env vars (see `.env.example`)
- Postgres: `POSTGRES_HOST/DB/USER/PASSWORD`. Hydra/identity: `HYDRA_PUBLIC_URL`, `HYDRA_PUBLIC_API_URL`, `HYDRA_PUBLIC_TOKEN_URL`, `HYDRA_CLIENT_ID/SECRET`, `IDENTITY_URL`, `HOST_URL`.
- External APIs: `USERINFO_API_URL/KEY`, `PROFILE_API_KEY`. Webhooks: `GITHUB_WEBHOOK_SECRET`, `GITHUB_WEBHOOK_REF`, optional `GITHUB_AUTH_TOKEN` for GitHub GraphQL.
- CORS/storage: `ALLOWED_ORIGINS`, `AWS_*` (S3). Local auth/dev: `BYPASS_OAUTH=true` to stub identity; `SMEE_TUNNEL` for local webhook relay.

Examples to follow
- REST: `GET /api/projects/:id` resolves by identifier+locale (uses `ProjectLoader`); `POST /api/projects/:project_id/images` attaches files; `POST /api/projects/:project_id/remix` creates a remix (requires auth).
- GraphQL query snippet: `projects(userId: "<uuid>") { edges { node { identifier name components { nodes { name extension } } } } }` and `project(identifier: "abc123") { name images { nodes { filename } } }`.

Where to look first
- Routes: `config/routes.rb`. Auth: `config/initializers/omniauth.rb`, `app/helpers/authentication_helper.rb`, `app/controllers/concerns/identifiable.rb`.
- Permissions: `app/models/ability.rb`. Domain ops: `lib/concepts/**`. Data models: `app/models/**`. API views: `app/views/api/**`. GraphQL types/mutations: `app/graphql/**`.