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

# CORS Allowed Origins

Add a comma separated list to the relevant enviroment settings. E.g for development in the `.env` file:

```
ALLOWED_ORIGINS=localhost:3002,localhost:3000
```

# Webhooks

This API receives push event data from the [Raspberry Pi Learning](https://github.com/raspberrypilearning) organisation via webhooks. These webhooks are mediated locally through `smee`, which runs in a Docker container. The webhook data is processed using the `github_webhooks` gem in the `github_webhooks_controller`.


# Authentication

We use Raspberry Pi accounts (aka Profile) as our identity provider, backed on to Hydra for consent and authorization.  To bypass this in development you can set

```
BYPASS_AUTH=yes
```

in your `.env` file.  You'll still need to pass an `Authorization` header to show you're logged in, but it can contain anything.  If you want to set a particular user ID, you can also set

```
BYPASS_AUTH_USER_ID="1AD9FD7D-65B0-4335-9B20-67AF8AD4F856"
```

if that's the user ID you wish.



