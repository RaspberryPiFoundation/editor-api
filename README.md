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
