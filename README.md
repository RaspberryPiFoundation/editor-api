# The Raspberry Pi Foundation Code Editor - API

Test Change

This document discusses the components used to build the Raspberry Pi Foundation Code Editor. It's a good starting point both for working on the editor itself and for using ideas or components from the editor in other projects.

The document assumes some familiarity with the app as a user. [Try it out](https://editor.raspberrypi.org) before reading further.

## API

The [editor API](https://github.com/RaspberryPiFoundation/editor-api) is a Rails monolith and is hosted at [`editor-api.raspberrypi.org`](https://editor-api.raspberrypi.org/). Through the combination of a REST interface and a GraphQL API, it provides mechanisms for:

- Session management
- User auth (delegated to [Raspberry Pi Accounts / Open ID Connect](https://github.com/RaspberryPiFoundation/profile)) and permissions (managed using the `cancancan` gem)
- Persistence of projects, including code files, data, images and metadata.

Individual projects can be requested from `/api/projects/{project_identifier}` and a list of a user's projects is available via the GraphQL API.

Project images are uploaded via `POST` requests to `/projects/{project_identfier}/images` and stored in an S3 bucket. However, the ability to upload images in the user interface is not currently enabled for safeguarding reasons.

A project remix is created via a `POST` request to `projects/{original_project_identifier}/remix`.

### Requests from UI to API

Currently requests to the API from a specific project page are generally performed via `axios`, with `AsyncThunk`s being used to manage the status of such requests and update the UI accordingly.

The My Projects page loads data and requests project renaming/deletion via GraphQL, with data stored in an Apollo cache. In the future, we aim to transition the whole app over to using the GraphQL/Apollo approach.

## Getting Started

### Initial Setup

Copy the `.env.example` file into a `.env` file.

From the project directory build the app using docker:

```
docker-compose build
```

Set up the database:

```
docker compose run api rails db:setup
```

### Running the app

Start the application and its dependencies via docker:

```
docker-compose up
```

#### Updating gems inside the container

This can be done with the `bin/with-builder.sh` script:
```
./bin/with-builder.sh bundle update
```
which should update the Gems in the container, without the need for rebuilding.

### CORS Allowed Origins

Add a comma separated list to the relevant enviroment settings. E.g for development in the `.env` file:

```
ALLOWED_ORIGINS=localhost:3002,localhost:3000
```

### Webhooks

This API receives push event data from the [Raspberry Pi Learning](https://github.com/raspberrypilearning) organisation via webhooks. These webhooks are mediated locally through `smee`, which runs in a Docker container. The webhook data is processed using the `github_webhooks` gem in the `github_webhooks_controller`.
