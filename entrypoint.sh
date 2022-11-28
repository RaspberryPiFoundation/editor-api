#!/bin/bash
set -e

built_lock_file="/tmp/Gemfile.lock"
current_lock_file="Gemfile.lock"

# Copy built lock file into container/host fs
function cp_built_lock_file() {
  cp "${built_lock_file}" "${current_lock_file}"
}

if [ -f "${current_lock_file}" ]; then
  diff="$(diff "${built_lock_file}" "${current_lock_file}")"
  if [ "${diff}" != "" 2>/dev/null ]; then
    cp_built_lock_file
  fi
else
  cp_built_lock_file
fi

# Remove a potentially pre-existing server.pid for Rails.
rm -f /myapp/tmp/pids/server.pid

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
