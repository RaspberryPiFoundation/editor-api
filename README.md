# The Raspberry Pi Foundation Code Editor - API

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

### Seeding

By default in development only, two tasks are called to seed data:

`rails projects:create_all`
`rails classroom_management:seed_a_school_with_lessons`

If needed manually the following task will create all projects:

`rails projects:create_all`

For classroom management the following scenarios modelled by the tasks:

`rails classroom_management:seed_an_unverified_school` - seeds an unverified school to test the onboarding flow
`rails classroom_management:seed_a_verified_school` - seeds only a verified school
`rails classroom_management:seed_a_school_with_lessons_and_students` - seeds a school with a class, two lessons, a project in each, and two students

To clear classroom management data the following cmd will remove the school associated with the `jane.doe@example.com` user, and associated school data:

`rails classroom_management:destroy_seed_data`

To override values, you can prefix the tasks with environment variables, for example:

`SEEDING_CREATOR_ID=00000000-0000-0000-0000-000000000000 rails classroom_management:seed_a_verified_school`

Also avilable to override are: `SEEDING_TEACHER_ID`.

> NOTE: The student ids and school id in the CM seeds are hard coded to match profile seed data.

#### Syncing the database from Production / Staging

##### Prerequisites

- You must have the [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli) installed
- You must be added to the Heroku app `editor-api-production` to sync from the production database
- You must be added to the Heroku app `editor-api-staging`, to sync from the staging database

#### Syncing from PRODUCTION...

| ... to ENV    | ... run this:                          |
| ------------- | -------------------------------------- |
| Local Dev Env | `./bin/db-sync/production-to-local.sh` |

##### Syncing from STAGING...

| ... to ENV    | ... run this:                       |
| ------------- | ----------------------------------- |
| Local Dev Env | `./bin/db-sync/staging-to-local.sh` |

The `*-to-local.sh` scripts will backup the database in your local terminal, then run an instance of the Docker container and run commands to populate your development DB with that data - see [./bin/db-sync/load-local-db.sh](./bin/db-sync/load-local-db.sh)

### Testing

Run the entire test suite using:

```
docker-compose run api rspec
```

Or individual specs using:

```
docker-compose run api rspec spec/path/to/spec.rb
```

### CORS Allowed Origins

Add a comma separated list to the relevant enviroment settings. E.g for development in the `.env` file:

```
ALLOWED_ORIGINS=localhost:3002,localhost:3000
```

### Webhooks

This API receives push event data from the [Raspberry Pi Learning](https://github.com/raspberrypilearning) organisation via webhooks. These webhooks are mediated locally through `smee`, which runs in a Docker container. The webhook data is processed using the `github_webhooks` gem in the `github_webhooks_controller`.
