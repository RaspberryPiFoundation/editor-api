#!/bin/bash
set -euo pipefail # Use strict-mode in based to ensure errors are surfaced early

# Check if bundle install needs to be run
bundle check >/dev/null 2>&1 || bundle install --jobs "${BUNDLE_JOBS:-4}"

# Check if yarn install needs to be run
if [ -f package.json ] && command -v yarn >/dev/null 2>&1; then
	yarn install --check-files --frozen-lockfile || yarn install --check-files
fi

# Prepare the database
bundle exec rails db:prepare

exec rdbg -n -o -c -- bundle exec rails s -p 3009 -b '0.0.0.0'
