# Moving the Code Editor into editor-api

## Why

`editor-standalone` builds two React SPAs from one shared `src/` tree: the editor
(`apps/editor/`) and Code Classroom (`apps/classroom/`). The editor is small — a home
page, a project index and a project show page — but it is not separable from classroom:
`apps/editor/src/**` is only an entry point, routes table, secondary nav and OIDC
config, while every page it renders (`src/components/LandingPage`,
`src/components/ProjectIndex`, `src/containers/ProjectComponentLoader`, `GlobalNav`,
`Footer`) is shared code classroom also uses. Changing the editor means reasoning about
classroom, and vice versa.

This engine gives the editor its own home. The project show page must keep working as it
does today, initialising the `<editor-wc>` web component from `editor-ui`. Everywhere
else the goal is less client-side JavaScript and more content rendered on the server.

## What has been done

Phases 0 and 1 are complete and verified against a running server, not only in specs.
61 specs, lint clean. In order:

| Commit | Delivered |
|---|---|
| `5db78ac6` | The engine itself, mounted at `/` behind `EDITOR_APP_HOSTS`; `EditorApp.serves_host?`, `EditorApp::Locale`, locale resolution, `/` → `/:locale` redirect, `OriginParser.parse` |
| `e8dd5804` | Fallout fix from that refactor: `CorpMiddleware` specs now set `ALLOWED_ORIGINS` with ClimateControl instead of stubbing `ENV#[]` |
| `0327b477` | Home page rendered on the server, translations for all five locales, landing page CSS and assets, `config.i18n.fallbacks` |
| `de5bc022` | Global nav via the Stencil web component's Rails build, with real per-language links and per-form CSRF tokens |
| `f88c2fd5` | Secondary nav as a view component, `BaseComponent`, and `/:locale/education` redirecting to Code Classroom |
| `d61ad7ca` | Footer as a view component, with the `show_footer?` opt-out for full-viewport pages |
| `37ed492b` | Fix for `Locales.load_locales` clobbering `I18n.available_locales` — see [Bugs found](#bugs-found-in-the-react-app--do-not-reintroduce) |

What exists in the engine now:

```
lib/editor_app.rb                              serves_host?, hosts
app/models/editor_app/locale.rb                SUPPORTED, SELECTABLE, resolve, projects_site
app/controllers/editor_app/
  application_controller.rb                    locale resolution, check_authorization, show_footer?
  home_controller.rb  locales_controller.rb  education_controller.rb
app/components/editor_app/
  base_component.rb  global_nav_component.rb  secondary_nav_component.rb  footer_component.rb
app/helpers/editor_app/application_helper.rb   editor_login_path, code_classroom_url, …
app/views/layouts/editor_app/application.html.erb
app/views/editor_app/home/show.html.erb
app/assets/stylesheets/editor_app/             application, landing_page, secondary_nav, footer (plain CSS)
config/locales/editor_app.{en,en-US,es-LA,fr-FR,ga-IE}.yml
```

Specs in the host tree: `spec/requests/editor_app/{mounting,home,education}_spec.rb`,
`spec/components/editor_app/*_spec.rb`, `spec/models/editor_app/locale_spec.rb`,
`spec/lib/editor_app_spec.rb`.

### What is left

| | |
|---|---|
| Next | Phase 2 (auth + token bridge) and Phase 3 (project show page) — independent of each other, and Phase 3 needs no token for starter projects |
| Not started | Phase 4 (project index), Phase 5 (cutover) |
| Blocked elsewhere | Hydra client registration — see [Outstanding dependency](#outstanding-dependency) |

**Dangling routes.** `config/routes.rb` already declares `projects#*` and
`session_tokens#show`, whose controllers do not exist yet. Requests to
`/:locale/projects…` or `/session/token` will raise until Phases 2 and 3 land. The
`session_tokens` route is a leftover from an earlier design and should be replaced by
the silent-renew routes described below.

Nothing of the project index or project show page is built. No JavaScript has been
written yet: there is no `app/javascript/editor_app/controllers/` content, so the
Plausible click events on the home page buttons are currently inert
`data-plausible-event` attributes awaiting a Stimulus controller.

## Architecture

### Where it lives

A mountable path-gem engine at the repo root (`gem 'editor_app', path: 'editor_app'`),
matching how `experience-cs` does it with `scratch_editor`. Rails has no convention for
in-repo engines; this is just what `rails plugin new <name> --mountable` produces.

The engine depends on host models (`Project`, `Ability`, `User`), so its specs live in
the host `spec/` tree following the repo's by-type layout —
`spec/requests/editor_app/`, `spec/components/editor_app/`, `spec/models/editor_app/`,
`spec/lib/editor_app_spec.rb`. That is what makes RSpec infer the spec type. There is no
dummy app.

### Mounting

`EditorApp.serves_host?` reads `EDITOR_APP_HOSTS`, parsed with the literal-or-regex
convention of `OriginParser.parse` in `lib/origin_parser.rb`. In the host
`config/routes.rb` the mount comes **last**, and the bare `root` is restricted to
non-editor hosts so `/` reaches the engine and redirects to a locale-prefixed path:

```ruby
constraints(->(request) { !EditorApp.serves_host?(request.host) }) { root to: 'auth#index' }
constraints(->(request) {  EditorApp.serves_host?(request.host) }) { mount EditorApp::Engine => '/' }
```

Everything else is declared above, so `/api/**`, `/admin`, `/graphql`, `/auth/**` and
`/github_webhooks` keep working on both hosts. `config/environments/production.rb` adds
`EditorApp.hosts` to `config.hosts`, without which the editor host is rejected.

### Styling, with no build step added

The React SCSS reached design-system-core only through `@include typography.style-N`,
and those mixins are pure wrappers over `--font-size-N` / `--font-weight-*` /
`--line-height-N` custom properties. Expanding them inline lets the engine ship **plain
CSS under Propshaft** — no Sass or Node toolchain in editor-api. Tokens come from the
prebuilt stylesheet via `DesignSystem::STYLESHEET_URL`. Propshaft rewrites relative
`url()` references to digested paths on its own.

`design_system_rails` only offers button, alert, accordion, tag, progress bar, markdown
and form components, so nav, footer, cards and the project list are engine-local view
components using the same tokens.

Only the **light** theme tokens are ported. The React app had a `--dark` block driven by
a persisted Redux setting; nothing outside the editor web component toggled it on these
pages. Dark mode on server-rendered pages is unbuilt.

### Components

Engine components inherit `EditorApp::BaseComponent`, which delegates route and engine
helpers to `helpers`, because neither is otherwise reachable from a component or its
template. Component specs must render through the engine controller or those helpers
resolve against the host application and silently produce different URLs:

```ruby
with_controller_class(EditorApp::HomeController) { render_inline(component) }
```

### Locale handling

`EditorApp::ApplicationController` resolves the locale in the order `src/utils/i18n.js`
used: path segment, then the `i18next` cookie, then `Accept-Language`, then `en`. It
sets `default_url_options[:locale]`, which makes engine route helpers ergonomic but
leaks `?locale=` into host application paths — hence `editor_login_path` and
`editor_logout_path` in `ApplicationHelper`, which pass `locale: nil` to suppress it.
Do not `.compact` that hash; it removes the very key doing the work.

The engine declares its own supported locales in `EditorApp::Locale::SUPPORTED` rather
than inferring them from which YAML files exist. Translations exist for `en`, `en-US`,
`es-LA`, `fr-FR` and `ga-IE` only; `config.i18n.fallbacks = [:en]` covers the rest, and
matches the `fallbackLng` the React app set.

## Remaining work

### Phase 2 — Auth and the token bridge

`editor-ui` reads its user from `localStorage[auth_key]` once at mount
(`src/web-component.jsx:227`) and re-reads it every 45s
(`src/hooks/useSyncUserFromLocalStorage.js`). Rails owns the session and keeps that key
populated, so **no `editor-ui` change is needed**.

- Extend `AuthController#callback` to honour `request.env['omniauth.origin']`
  (`origin_param: 'returnTo'` is already configured) with an allow-list check, so login
  returns to the page you came from.
- Fix `redirect_to admin_root_path if current_user.admin?` in that callback. On the
  editor host it sends admins to `/admin` from the editor home page.
- Add `allow-u13-login` to the OmniAuth scope. It is already permitted on both clients.
- Store `access_token` and `expires_at` in `session[:oauth_credentials]` rather than
  widening `User::ATTRIBUTES`. Watch the 4KB cookie store: there is no `session_store`
  initializer and the session already carries all of `session[:current_user]`.
- Bridge: the page embeds `<script type="application/json">` with the token, then a
  synchronous inline script writes `localStorage[auth_key]`, and only then loads
  `web-component.js` deferred. That ordering is what lets `loadInitialUser()` find a
  user. No CSP is enforced today, so no nonce is needed.
- `auth_key` is ours to choose but must match between the bridge and the
  `<editor-wc auth_key=…>` attribute. Derive it from `HYDRA_PUBLIC_URL` and the client
  id, in the format `getOidcAuthKey` used.

**Renewal is by silent re-authorisation, not refresh tokens.** Access tokens last an
hour and an editor page may be open far longer, so the token in localStorage has to be
replaced while the page lives. `offline_access` was rejected deliberately: Hydra is told
`remember_for = 0` at login (`profile/app/lib/login.js`), so its session cookie lasts
the whole browser session, whereas a refresh token expires in its own right — 2h locally
— and would die on an idle page. A probe of the authorize endpoint also confirmed the
client is refused `offline_access` today (`invalid_scope`).

- `SilentRenewController#start` builds the Hydra authorize URL itself with `prompt=none`,
  a `state` in the session, and `redirect_uri` pointing at `#callback`. It bypasses
  OmniAuth on purpose: the request phase requires a POST under
  `omniauth-rails_csrf_protection`, which an iframe navigation cannot do.
- `#callback` exchanges the code server-side, updates the session, and renders a bare
  page whose only job is writing the fresh token to `localStorage[auth_key]`. Same-origin
  with the editor page, so no postMessage. The existing 45s poll picks it up.
- Load `#start` in a **hidden iframe** shortly before expiry. Never a top-level
  redirect: that tears down `<editor-wc>` and loses unsaved code, which is the whole
  reason for renewing. The iframe works because the editor host and the auth host are
  both under `raspberrypi.org`, so Hydra's session cookie is same-site there and is not
  affected by third-party cookie restrictions.
- On `error=login_required` the session has genuinely gone. Surface a "log in again"
  prompt in place and never navigate away, so the user can still recover their work.

#### Requirement: the editor host must use the editor Hydra client

**Two Hydra clients, not one, and the editor host must use the editor client** — the one
defined by `profile/dev-config/hydra/clients/v2/editor-client.json`, client id
`editor-dev` locally. The admin and API pages on the editor-api host keep using
`HYDRA_CLIENT_ID` (`editor-dashboard-dev` locally). This is a requirement, not a
preference.

Why it matters beyond tidiness: Profile resolves the `roles` claim **per client id**
(`Assignment.getUserRolesForApplication(user, clientID)` in
`profile/app/services/account-authorization/scopes.js`), and editor-api reads that claim
for `User#admin?`, which drives `Ability`. One shared client would give a session created
on the public editor host the same `editor-admin` role as the admin dashboard. Using
distinct clients also sidesteps `frontchannel_logout_uri` being a single URI per client,
unlike `redirect_uris`.

**Implement it as a public client with PKCE, and change nothing about the client.**
`editor-client.json` is registered `"token_endpoint_auth_method": "none"`, so Hydra
expects no client authentication, whereas this app's OmniAuth config sends a secret with
`auth_scheme: :basic_auth`. Do not flip that client to `client_secret_basic` to resolve
it: `editor-dev` is also editor-ui's dev client (`editor-ui/.env.example`) and its
production counterpart is the SPA's client, both of which are browser apps that require
`none`. A client has one `token_endpoint_auth_method`, so changing it would break them.

`omniauth-oauth2` supports PKCE (`pkce: true` — see `omniauth/strategies/oauth2.rb:32`,
which adds `code_challenge` on the authorize request and `code_verifier` on the token
request). That lets editor-api authenticate against the unmodified public client.

OmniAuth also supports a per-request `setup` callable and runs it on **both** the request
and callback phases (`omniauth/strategy.rb:234` and `:269`), so one provider can switch
client and auth style by host — keeping a single `/auth/rpi` and `/auth/callback`, and
leaving the global nav and every login link untouched:

```ruby
setup: lambda { |env|
  next unless EditorApp.serves_host?(Rack::Request.new(env).host)

  strategy = env['omniauth.strategy']
  strategy.options[:client_id] = ENV.fetch('EDITOR_HYDRA_CLIENT_ID', nil)
  strategy.options[:client_secret] = nil
  strategy.options[:pkce] = true
}
```

Verify at implementation time that no `Authorization: Basic` header is sent on the token
request once `client_secret` is nil — Hydra rejects client authentication outright for a
`none` client. `client_options[:auth_scheme]` may need setting to `:request_body` for the
editor host, and the `oauth2` gem's behaviour with a nil secret is worth asserting in a
spec rather than assumed.

A consequence to accept deliberately: `editor-admin` should not be assigned to the editor
client in Profile, so **admins are not admins on the editor host**. That is the intended
behaviour — the admin dashboard lives on the editor-api host — and it also removes the
`redirect_to admin_root_path` misfire noted above.

### Phase 3 — Project show page

- `ProjectsController#show`: `ProjectLoader.new(params[:identifier], [params[:locale], 'en', nil])`
  then `authorize! :show, @project`.
- Redirect `project_type == 'scratch'` to `EXPERIENCE_CS_WEB_URL`, as
  `src/components/ProjectPage/ProjectPage.jsx` does.
- Render `<editor-wc>` with the attribute set from
  `src/components/Editor/Project/Project.jsx`. Two things improve for free:
  `friendly_errors_enabled` can read `Flipper.enabled?` directly instead of
  round-tripping `/api/features`, and the API endpoint is now same-origin.
  `offline_enabled` is `"false"` while the service worker is out of scope.
- `EditorApp::WebComponent.script_url` should port the `latest_version` indirection from
  `src/scripts/getEditorWebComponentURL.js`, cached in `Rails.cache`.
- Override `show_footer?` to `false`; the editor fills the viewport.
- One Stimulus controller replaces the `useEffect` listeners in
  `src/containers/ProjectComponentLoader.jsx`, for the events in
  `editor-ui/src/events/WebComponentCustomEvents.js`:
  `editor-projectIdentifierChanged` → `history.replaceState`;
  `editor-navigateToProjectsPage` → the index; `editor-projectLoadFailed` → error page;
  `editor-logIn` → submit the login form.
- Not-found and access-denied become Rails 404/403, not the React modals.

Anonymous starter projects (`blank-python-starter`, `blank-html-starter`) need no token,
so this phase can be built and verified before Phase 2 exists.

### Phase 4 — Project index, create, rename, delete

- `#index` uses the same filter as `Types::QueryType#projects`:
  `Project.accessible_by(current_ability, :show).where(user_id: current_user.id, school_id: nil, lesson_id: nil).order(updated_at: :desc)`,
  paginated with the `kaminari` gem already in the Gemfile. The GraphQL cursor
  "Load more" becomes a Turbo-appended next-page link.
- Login required; students get 403, matching `ProjectLayout`'s student redirect.
- Port `ProjectIndexHeader`, `ProjectListTable`, `ProjectListItem` as view components.
  "Edited X ago" uses `time_ago_in_words` rather than `date-fns`.
- `#create`, `#update`, `#destroy` call `Project::Create` and `Project::Update` in
  `lib/concepts/project/operations/`. Starter content mirrors
  `src/utils/defaultProjects.js`: an empty `main.py`, or empty `index.html` + `style.css`.
  Confirm whether the index should also offer `code_editor_scratch`, which the React
  modal offers behind a feature flag.
- Forms in `<dialog>` inside Turbo Frames, flashes via Turbo Streams, one small Stimulus
  controller to open and close.

### Phase 5 — Cutover

- Keep editor-standalone's origin in `ALLOWED_ORIGINS` until it is retired. API calls are
  same-origin now, so CORS is off the critical path for the editor.
- Point the editor host at editor-api, leaving editor-standalone deployed until parity is
  confirmed.
- Then remove from editor-standalone: `apps/editor/`, the
  `build:editor`/`start:editor`/`serve:editor` scripts, `cypress/e2e/editor/` and its
  helpers, and the editor entry in the `ci-cd.yml` matrix. Relocate any shared `src/**`
  files only the editor used.
- Crowdin: the engine's YAML becomes a new source in editor-api's `crowdin.yml`. Remove
  the editor keys from `editor-standalone/public/translations/en.json` only once that
  source is live, so no strings are lost.

## Out of scope

`/embed/viewer/:identifier`, a dedicated `/error` page, the service worker and offline
mode, the Blocks/Scratch editor path, dark mode, and the whole classroom app.

`/education` is **not** being ported. Its entire content was a notice that Code Editor
for Education is now Code Classroom, so `EducationController` redirects there instead.

## Outstanding dependency

Hydra client registrations live outside this repo and are per environment. Given the
requirement above, the registration that matters is the **editor** client, not the
dashboard one.

Locally, `editor-client.json` already lists
`http://editor.localhost:3009/auth/callback` and `/auth/silent_renew`, so dev needs no
registration change once the app is pointed at `editor-dev`. Note that
`hydra import oauth2-client` refuses to update an existing client, so applying any edit
means deleting the client first — re-running `seed.sh` alone will not do it.

For staging and production the editor client needs the editor host's callback and
silent-renew URIs added, and **nobody can log in on the editor host until that lands**.
No new grant type and no new scope are required.

Clean up before starting Phase 2: local dev currently carries a throwaway edit adding
`http://editor.localhost:3009/...` to `editor-dashboard-client.json`, made while
diagnosing a `redirect_uri` mismatch. It is the wrong client under this requirement and
should be reverted.

## Bugs found in the React app — do not reintroduce

1. **`Locales.load_locales` clobbered `I18n.available_locales`.** It assigned rather than
   merged, as a side effect of autoloading `UploadJob` to fill a constant, and its list
   has no `en-US` — so every `/en-US` page would have raised `I18n::InvalidLocale` once
   that class loaded. Fixed here; the method still returns its original list so
   `UploadJob` validation is unchanged.
2. **The student landing view used two translation keys absent from every locale file**,
   so it rendered raw key names. It now uses the existing translated
   "Go to Code Classroom".
3. **The footer gated the safeguarding report on a truthy-for-any-signed-in-user Redux
   value**, so it showed the report with an undefined school id. Now gated on actual
   active-school membership.
4. The student and teacher login links wrote to `localStorage` on the editor origin for
   Code Classroom to read on *its* origin. That cannot work; the writes are dropped.

## Local development

```bash
# .env
EDITOR_APP_HOSTS=editor.localhost
```

Then `http://editor.localhost:3009/en`. Rails allows `.localhost` hosts in development,
so no `config.hosts` change is needed locally. Restart the container after changing
`.env`; dotenv only reads it at boot.

```bash
docker compose run --rm api bundle exec rspec spec/requests/editor_app spec/components/editor_app
docker compose run --rm api bundle exec rubocop editor_app
```

Use `bundle exec`. A bare `rspec` hits a gem activation conflict unrelated to this work.
