#!/bin/bash -eu

export DISABLE_DATABASE_ENVIRONMENT_CHECK=1
echo 'Dropping databases'
bin/rails db:drop
echo 'Recreating empty development & test databases'
bin/rails db:create
echo 'Replacing databases'
export PGPASSWORD="$POSTGRES_PASSWORD"
psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c 'CREATE SCHEMA IF NOT EXISTS heroku_ext;'
pg_restore --verbose --if-exists --clean --no-acl --no-owner -h $POSTGRES_HOST -w -U $POSTGRES_USER -d $POSTGRES_DB /app/tmp/heroku-data/latest.dump
echo 'Setting the database environment'
bin/rails db:environment:set RAILS_ENV=development
echo 'Running any remaining migrations'
bin/rails db:migrate

# update rails active storage table to local service
PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c "UPDATE active_storage_blobs SET service_name = 'local';"
