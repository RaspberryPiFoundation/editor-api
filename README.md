# Raspberry Pi Foundation Code Editor API

The editor API is a Rails monolith and is hosted at [`editor-api.raspberrypi.org`](https://editor-api.raspberrypi.org/). Through the combination of a REST interface and a GraphQL API, it provides mechanisms for:

- Session management
- User auth (delegated to [Raspberry Pi Accounts / Open ID Connect](https://github.com/RaspberryPiFoundation/profile)) and permissions (managed using the `cancancan` gem)
- Persistence of projects, including code files, data, images and metadata
- Management of schools, school classes, lessons, teachers and students for Code Editor for Education (CEfE)

## Getting Started

### Initial Setup

Copy the `.env.example` file into a `.env` file.

From the project directory build the app using docker:

```
docker-compose build
```

Set up the database:

```
docker compose run --rm api rails db:setup
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

`docker compose run --rm api rails projects:create_all`
`docker compose run --rm api rails for_education:seed_a_school_with_lessons_and_students`

If needed manually the following task will create all projects:

`docker compose run --rm api rails projects:create_all`

For CEfE the following scenarios are modelled by the tasks:

`docker compose run --rm api rails for_education:seed_an_unverified_school` - seeds an unverified school to test the onboarding flow
`docker compose run --rm api rails for_education:seed_a_verified_school` - seeds only a verified school
`docker compose run --rm api rails for_education:seed_a_school_with_lessons_and_students` - seeds a school with a class, two lessons, a project in each, and two students

To clear CEfE data the following cmd will remove the school associated with the `jane.doe@example.com` user, and associated school data:

`rails for_education:destroy_seed_data`

To override values, you can prefix the tasks with environment variables, for example:

`SEEDING_CREATOR_ID=00000000-0000-0000-0000-000000000000 rails for_education:seed_a_verified_school`

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

Handled in `config/initializers/cors.rb`.

### Webhooks

This API receives push event data from the [Raspberry Pi Learning](https://github.com/raspberrypilearning) organisation via webhooks. This data is used to create or update code projects related to the [Code Club Projects Site](https://projects.raspberrypi.org), and is processed using the `github_webhooks` gem in the `github_webhooks_controller`. For development purposes, these webhooks are mediated locally through `smee`, which runs in a Docker container.

## Usage

### Projects

Individual projects can be requested from `/api/projects/{project_identifier}` and a list of a user's projects is available via the GraphQL API.

Project images are uploaded via `POST` requests to `/projects/{project_identfier}/images` and stored in an S3 bucket.

A project remix is created via a `POST` request to `projects/{original_project_identifier}/remix`.

### Code Editor for Education

Editor API provides routes for managing resources such as schools, school classes and lessons, as well as for inviting teachers and managing student accounts via `profile` requests.

