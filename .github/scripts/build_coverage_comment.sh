#!/usr/bin/env bash
set -euo pipefail

coverage='unavailable'
if [ -s coverage/.last_run.json ]; then
  coverage=$(jq -r 'if .result.line then .result.line else .result.covered_percent end' coverage/.last_run.json)
fi

if [ -z "${coverage}" ] || [ "${coverage}" = 'null' ]; then
  coverage='unavailable'
fi

run_url="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"

if [ "${coverage}" = 'unavailable' ]; then
  message=$(
    cat <<EOF
### Test coverage
SimpleCov coverage data was unavailable for this run.
Run: ${run_url}
EOF
  )
else
  message=$(
    cat <<EOF
### Test coverage
${coverage}% line coverage reported by SimpleCov.
Run: ${run_url}
EOF
  )
fi

{
  echo "message<<'EOF'"
  echo "${message}"
  echo 'EOF'
} >> "${GITHUB_OUTPUT}"
