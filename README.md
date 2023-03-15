# README


# Initial Setup

Copy the `.env.example` file into a `.env` file.

From the project directory build the app using docker:

```
docker-compose build
```

Set up the database:

```
docker compose run api rails db:setup
```

# Running the app

Start the application and its dependencies via docker:

```
docker-compose up
```

## Updating gems inside the container

This can be done with the `bin/with-builder.sh` script:
```
./bin/with-builder.sh bundle update
```
which should update the Gems in the container, without the need for rebuilding.

## CORS Allowed Origins

Add a comma separated list to the relevant environment settings. E.g for development in the `.env` file:

```
ALLOWED_ORIGINS=localhost:3002,localhost:3000
```

## Webhooks

This API receives push event data from the [Raspberry Pi Learning](https://github.com/raspberrypilearning) organisation via webhooks. These webhooks are mediated locally through `smee`, which runs in a Docker container. The webhook data is processed using the `github_webhooks` gem in the `github_webhooks_controller`.

## Authorization

We use OIDC for authentication and authorization in the Editor UI.  For endpoints that require authorization, sends an  `Authorized:` header containing the user's access token, which is then validated with a Hydra instance. This validation is done through the Hydra admin API [introspect OAuth2 access](https://www.ory.sh/docs/hydra/reference/api#tag/oAuth2/operation/introspectOAuth2Token).  Our Hydra admin interface uses a pre-shared secret for access, set in the environment as `HYDRA_ADMIN_API_KEY`.

This can also be bypassed for development work, by setting `BYPASS_AUTH` to `yes` in your `.env` file.  This will ensure that requests with an `Authorization` header are honoured, and a specific user ID is set.

# ⚠️ REST API is deprecated

We're moving towards using a GraphQL API replacement for all endpoints currently using REST.  As such no further work will be conducted on the REST API endpoints in `app/controllers/api`, and we'd expect all requests to be mediated via the GraphQL API.  There is a [GraphiQL](https://github.com/graphql/graphiql) instance available at the root of the API where queries can be tested.

