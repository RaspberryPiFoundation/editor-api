#!/usr/bin/env bash
set -euo pipefail

marker='<!-- simplecov-coverage -->'
body="${marker}"$'\n'"${COVERAGE_MESSAGE:-}"

if [ -z "${COVERAGE_MESSAGE:-}" ]; then
  echo 'COVERAGE_MESSAGE is empty; skipping PR comment.'
  exit 0
fi

pr_number=$(jq -r '.pull_request.number // empty' "${GITHUB_EVENT_PATH}")
if [ -z "${pr_number}" ]; then
  echo 'No pull request number in event payload; skipping PR comment.'
  exit 0
fi

owner_repo="${GITHUB_REPOSITORY}"
owner="${owner_repo%%/*}"
repo="${owner_repo#*/}"
api_base="https://api.github.com/repos/${owner}/${repo}/issues"

comments_json=$(curl -sS -f \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H 'Accept: application/vnd.github+json' \
  "${api_base}/${pr_number}/comments?per_page=100")

existing_comment_id=$(echo "${comments_json}" | jq -r --arg marker "${marker}" \
  'map(select(.user.type == "Bot" and (.body // "" | contains($marker)))) | .[0].id // empty')

payload=$(jq -n --arg body "${body}" '{body: $body}')

if [ -n "${existing_comment_id}" ]; then
  curl -sS -f \
    -X PATCH \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H 'Accept: application/vnd.github+json' \
    "${api_base}/comments/${existing_comment_id}" \
    -d "${payload}" > /dev/null
  echo "Updated coverage comment ${existing_comment_id} on PR #${pr_number}."
else
  curl -sS -f \
    -X POST \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H 'Accept: application/vnd.github+json' \
    "${api_base}/${pr_number}/comments" \
    -d "${payload}" > /dev/null
  echo "Created coverage comment on PR #${pr_number}."
fi
