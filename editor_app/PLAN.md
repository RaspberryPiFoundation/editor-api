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

Phases 0, 1 and 2 are complete and verified against a running server, not only in
specs. 92 specs, lint clean. In order:

| Commit | Delivered |
|---|---|
| `5db78ac6` | The engine itself, mounted at `/` behind `EDITOR_APP_HOSTS`; `EditorApp.serves_host?`, `EditorApp::Locale`, locale resolution, `/` → `/:locale` redirect, `OriginParser.parse` |
| `e8dd5804` | Fallout fix from that refactor: `CorpMiddleware` specs now set `ALLOWED_ORIGINS` with ClimateControl instead of stubbing `ENV#[]` |
| `0327b477` | Home page rendered on the server, translations for all five locales, landing page CSS and assets, `config.i18n.fallbacks` |
| `de5bc022` | Global nav via the Stencil web component's Rails build, with real per-language links and per-form CSRF tokens |
| `f88c2fd5` | Secondary nav as a view component, `BaseComponent`, and `/:locale/education` redirecting to Code Classroom |
| `d61ad7ca` | Footer as a view component, with the `show_footer?` opt-out for full-viewport pages |
| `37ed492b` | Fix for `Locales.load_locales` clobbering `I18n.available_locales` — see [Bugs found](#bugs-found-in-the-react-app--do-not-reintroduce) |
| `a3f78f84` | The editor host logging in against the **editor** Hydra client: `EditorHydraClient`, OmniAuth `setup` swapping client by host, public client + PKCE + `:request_body`, `allow-u13-login` added to the scope |
| `cbf0ebac` | Login returning to `omniauth.origin` behind a local-path check, the `admin_root_path` redirect demoted to a fallback, logout returning to the host it was triggered from, `session[:oauth_expires_at]` |
| `2287c6f9` | The token bridge: `AuthTokenComponent` writes `localStorage[auth_key]` from a JSON data block in `<head>`, and clears it when signed out |
| `f905240b` | Silent renewal: `SilentRenewController#start`/`#callback`, `User.from_id_token`, `SessionRenewalComponent`, `session_renewal.js` scheduling a hidden iframe, and the in-place "log in again" prompt |

What exists in the engine now:

```
lib/editor_app.rb                              serves_host?, hosts
app/models/editor_app/locale.rb                SUPPORTED, SELECTABLE, resolve, projects_site
app/controllers/editor_app/
  application_controller.rb                    locale resolution, check_authorization, show_footer?
  home_controller.rb  locales_controller.rb  education_controller.rb
app/components/editor_app/
  base_component.rb  global_nav_component.rb  secondary_nav_component.rb  footer_component.rb
  auth_token_component.rb                      localStorage[auth_key] bridge
  session_renewal_component.rb                 renewal script + "log in again" prompt
app/helpers/editor_app/application_helper.rb   editor_login_path, code_classroom_url, …
app/views/layouts/editor_app/application.html.erb
app/views/editor_app/home/show.html.erb
app/assets/javascripts/editor_app/session_renewal.js
app/assets/stylesheets/editor_app/             application, landing_page, secondary_nav, footer (plain CSS)
config/locales/editor_app.{en,en-US,es-LA,fr-FR,ga-IE}.yml
```

And in the host tree: `lib/editor_hydra_client.rb`,
`app/controllers/silent_renew_controller.rb`, `app/views/silent_renew/callback.html.erb`,
`User.from_id_token`.

Specs in the host tree: `spec/requests/editor_app/{mounting,home,education}_spec.rb`,
`spec/requests/{auth,silent_renew}_spec.rb`, `spec/components/editor_app/*_spec.rb`,
`spec/models/editor_app/locale_spec.rb`,
`spec/lib/{editor_app,editor_hydra_client}_spec.rb`.

### What is left

| | |
|---|---|
| Next | Phase 3 (project show page) — needs no token for starter projects |
| Not started | Phase 4 (project index), Phase 5 (cutover) |
| Blocked elsewhere | Hydra client registration for staging and production — see [Outstanding dependency](#outstanding-dependency) |

**Dangling route.** `session_tokens#show` has been replaced by the silent-renew routes
and is gone from `config/routes.rb`. `projects#*` is still declared without a
controller, so `/:locale/projects…` raises until Phase 3 lands.

Nothing of the project index or project show page is built. The only JavaScript is
`app/assets/javascripts/editor_app/session_renewal.js`, served by Propshaft; there is
still no `app/javascript/editor_app/controllers/` content and no Stimulus, so the
Plausible click events on the home page buttons are currently inert
`data-plausible-event` attributes.

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

### Phase 2 — Auth and the token bridge — **done**

How it ended up working, and the decisions worth keeping.

**Two Hydra clients, and the editor host uses the editor one.** Profile resolves the
`roles` claim per client id (`Assignment.getUserRolesForApplication(user, clientID)` in
`profile/app/services/account-authorization/scopes.js`), and editor-api reads that claim
for `User#admin?`, which drives `Ability`. One shared client would give a session created
on the public editor host the same `editor-admin` role as the admin dashboard. Distinct
clients also sidestep `frontchannel_logout_uri` being a single URI per client, unlike
`redirect_uris`. The admin and API pages on the editor-api host keep using
`HYDRA_CLIENT_ID`; the editor host uses `EDITOR_HYDRA_CLIENT_ID` (`editor-dev` locally).

The editor client is registered `"token_endpoint_auth_method": "none"`, and **nothing
about the client was changed** — it is also editor-ui's browser client, which requires
`none`. So `EditorHydraClient.configure_strategy` runs from OmniAuth's per-request
`setup` callable, which fires on **both** the request and callback phases
(`omniauth/strategy.rb:234` and `:269`), and switches client id, clears the secret, sets
`pkce: true` and — this is the part that is easy to miss — sets
`client_options[:auth_scheme]` to `:request_body`. With `:basic_auth` the `oauth2` gem
sends `Authorization: Basic <id>:` even when the secret is nil, and Hydra rejects client
authentication outright for a `none` client. There is a spec asserting no Authorization
header is produced. Mutating `strategy.options` per request is safe because
`Strategy#call` does `dup.call!(env)` and `initialize_copy` dups the Hashie::Mash
options deeply.

A consequence accepted deliberately: `editor-admin` should not be assigned to the editor
client in Profile, so **admins are not admins on the editor host**.

**Login returns where it started.** `AuthController#callback` honours
`request.env['omniauth.origin']` (OmniAuth is configured `origin_param: 'returnTo'`) when
it is a path on this site — `%r{\A/(?![\\/])}`, which rejects `//host` and absolute
URLs. `redirect_to admin_root_path if current_user.admin?` is now only the fallback when
no origin was named. Logging out returns to `request.base_url` on editor hosts rather
than always `HOST_URL`.

**The token bridge.** `EditorApp::AuthTokenComponent` renders in `<head>`: a
`<script type="application/json">` data block holding an oidc-client-ts shaped user
(`access_token`, `token_type`, `scope`, `expires_at`, `profile`), then a synchronous
inline script that copies its `textContent` into `localStorage[auth_key]`. Synchronous
and in `<head>` is what guarantees the key is populated before any deferred script can
mount `<editor-wc>` and call `loadInitialUser()`. When nobody is signed in the same
script *removes* the key — that is what clears it after logging out. The payload is
`ERB::Util.json_escape`d rather than interpolated into JavaScript. No `editor-ui` change
was needed.

`auth_key` is `oidc.user:#{HYDRA_PUBLIC_URL}:#{EDITOR_HYDRA_CLIENT_ID}`, the format
`getOidcAuthKey` used. It is ours to choose but must match the `<editor-wc auth_key=…>`
attribute Phase 3 will set — read it from `EditorHydraClient.auth_key`.

The access token was **not** duplicated into the session: `User::ATTRIBUTES` already
includes `token`, so it is in `session[:current_user]` already, and the session cookie
only has 4KB. Only `session[:oauth_expires_at]` was added.

**Renewal is silent re-authorisation, not refresh tokens.** `offline_access` was rejected
deliberately: Hydra is told `remember_for = 0` at login (`profile/app/lib/login.js`), so
its session cookie lasts the whole browser session, whereas a refresh token expires in
its own right — 2h locally — and would die on an idle page. A probe of the authorize
endpoint also confirmed the client is refused `offline_access` today (`invalid_scope`).

- `SilentRenewController#start` builds the authorize URL itself with `prompt=none`, a
  `state` and PKCE verifier in the session, and `redirect_uri` pointing at `#callback` at
  `/auth/silent_renew`. It bypasses OmniAuth on purpose: the request phase requires a
  POST under `omniauth-rails_csrf_protection`, which an iframe navigation cannot do.
- `#callback` exchanges the code server-side against the public client, rebuilds the user
  from the id token with `User.from_id_token` (so `current_user.token` stays fresh for
  server-side Profile API calls too), and renders a bare page that writes the new token to
  `localStorage[auth_key]` and `postMessage`s the outcome to its opener. Same-origin, so
  the existing 45s poll in `useSyncUserFromLocalStorage` picks the token up.
- `session_renewal.js` schedules the hidden iframe two minutes before expiry and
  reschedules from the `expiresAt` in the message. It returns early when
  `window.parent !== window` so the iframe never schedules its own renewal. Never a
  top-level redirect: that tears down `<editor-wc>` and loses unsaved code, which is the
  whole reason for renewing.
- On failure `EditorApp::SessionRenewalComponent`'s prompt is unhidden in place and a
  `editor-app:session-expired` event is dispatched on `window`. The failure path renders
  no `AuthTokenComponent`, so the stored token is left alone and unsaved work is still
  recoverable.

Still open from this phase: `editor_app.session.expired` and
`editor_app.session.log_in_again` exist in `en` only and fall back to English elsewhere,
so they need to go through Crowdin with the rest of the engine's strings in Phase 5.

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

Locally, `editor-client.json` lists
`http://editor.localhost:3009/auth/callback` and `/auth/silent_renew`, so dev needs no
registration change once the app is pointed at `editor-dev`. Note that
`hydra import oauth2-client` refuses to update an existing client, so applying any edit
means deleting the client first — re-running `seed.sh` alone will not do it.

For staging and production the editor client needs the editor host's callback and
silent-renew URIs added, and **nobody can log in on the editor host until that lands**.
No new grant type and no new scope are required.

Still to clean up in the `profile` working tree: it carries a throwaway edit adding
`http://editor.localhost:3009/...` to `editor-dashboard-client.json`, made while
diagnosing a `redirect_uri` mismatch. It is the wrong client under this requirement and
should be reverted. The matching edit to `editor-client.json` is the one to keep, and is
also uncommitted.

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
EDITOR_HYDRA_CLIENT_ID=editor-dev
```

Then `http://editor.localhost:3009/en`. Rails allows `.localhost` hosts in development,
so no `config.hosts` change is needed locally. Restart the container after changing
`.env`; dotenv only reads it at boot.

```bash
docker compose run --rm api bundle exec rspec spec/requests/editor_app spec/components/editor_app \
  spec/requests/auth_spec.rb spec/requests/silent_renew_spec.rb spec/lib/editor_hydra_client_spec.rb
docker compose run --rm api bundle exec rubocop editor_app
```

Use `bundle exec`. A bare `rspec` hits a gem activation conflict unrelated to this work.
