#!/bin/bash
# School Import Job Status Script
# Usage: ./scripts/status.sh <job_id>

set -e

# Check if job_id is provided
if [ -z "$1" ]; then
  echo "Error: Job ID required"
  echo "Usage: $0 <job_id>"
  echo "Example: $0 550e8400-e29b-41d4-a716-446655440000"
  exit 1
fi

# Check if TOKEN is set
if [ -z "$TOKEN" ]; then
  echo "Error: TOKEN environment variable not set"
  echo "Please set TOKEN before running:"
  echo "  export TOKEN='your_token_here'"
  exit 1
fi

JOB_ID="$1"
API_URL="${API_URL:-http://localhost:3009/api/school_import_jobs}"

# Make the API call
response=$(curl -sS -H "Authorization: $TOKEN" "$API_URL/$JOB_ID" \
  -w "\n%{http_code}")

# Extract HTTP status code (last line)
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

# Check response
if [ "$http_code" -ne 200 ]; then
  echo "✗ Failed to get job status (HTTP $http_code)"
  echo ""
  echo "$body" | jq '.' 2>/dev/null || echo "$body"
  exit 1
fi

# Parse JSON response
status=$(echo "$body" | jq -r '.status' 2>/dev/null)
created_at=$(echo "$body" | jq -r '.created_at' 2>/dev/null)
finished_at=$(echo "$body" | jq -r '.finished_at' 2>/dev/null)
job_class=$(echo "$body" | jq -r '.job_class' 2>/dev/null)

# Display job info
echo "════════════════════════════════════════════════════════════════"
echo "  School Import Job Status"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Job ID:      $JOB_ID"
echo "Status:      $status"
echo "Job Type:    $job_class"
echo "Created:     $created_at"

if [ "$finished_at" != "null" ]; then
  echo "Finished:    $finished_at"
fi

echo ""

# Check if job has results
has_results=$(echo "$body" | jq 'has("results")' 2>/dev/null)

if [ "$has_results" == "true" ]; then
  successful=$(echo "$body" | jq -r '.results.successful | length' 2>/dev/null)
  failed=$(echo "$body" | jq -r '.results.failed | length' 2>/dev/null)
  total=$((successful + failed))
  
  echo "════════════════════════════════════════════════════════════════"
  echo "  Summary"
  echo "════════════════════════════════════════════════════════════════"
  echo ""
  echo "Total Schools:    $total"
  echo "✓ Successful:     $successful"
  echo "✗ Failed:         $failed"
  echo ""
  
  # Show successful schools
  if [ "$successful" -gt 0 ]; then
    echo "════════════════════════════════════════════════════════════════"
    echo "  Successful Schools"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    printf "%-40s %-12s %-40s\n" "NAME" "CODE" "OWNER EMAIL"
    echo "────────────────────────────────────────────────────────────────"
    
    echo "$body" | jq -r '.results.successful[] | "\(.name)|\(.code)|\(.owner_email // "N/A")"' 2>/dev/null | while IFS='|' read -r name code email; do
      # Truncate long names
      if [ ${#name} -gt 38 ]; then
        name="${name:0:35}..."
      fi
      if [ ${#email} -gt 38 ]; then
        email="${email:0:35}..."
      fi
      printf "%-40s %-12s %-40s\n" "$name" "$code" "$email"
    done
    echo ""
  fi
  
  # Show failed schools
  if [ "$failed" -gt 0 ]; then
    echo "════════════════════════════════════════════════════════════════"
    echo "  Failed Schools"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    printf "%-35s %-24s %-40s\n" "NAME" "ERROR CODE" "ERROR MESSAGE"
    echo "────────────────────────────────────────────────────────────────"
    
    echo "$body" | jq -r '.results.failed[] | "\(.name)|\(.error_code // "UNKNOWN")|\(.error)"' 2>/dev/null | while IFS='|' read -r name code error; do
      # Truncate long values
      if [ ${#name} -gt 33 ]; then
        name="${name:0:30}..."
      fi
      if [ ${#error} -gt 38 ]; then
        error="${error:0:35}..."
      fi
      printf "%-35s %-24s %-40s\n" "$name" "$code" "$error"
    done
    echo ""
  fi
  
  # Show detailed JSON if requested
  if [ "$2" == "--json" ]; then
    echo "════════════════════════════════════════════════════════════════"
    echo "  Full JSON Response"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "$body" | jq '.' 2>/dev/null || echo "$body"
    echo ""
  fi
  
elif [ "$status" == "running" ] || [ "$status" == "queued" ]; then
  echo "Job is still $status... check again in a moment"
  echo ""
  echo "Run this command again:"
  echo "  $0 $JOB_ID"
  echo ""
elif [ "$status" == "failed" ]; then
  echo "════════════════════════════════════════════════════════════════"
  echo "  Job Failed"
  echo "════════════════════════════════════════════════════════════════"
  echo ""
  error=$(echo "$body" | jq -r '.error' 2>/dev/null)
  if [ "$error" != "null" ]; then
    echo "Error: $error"
  else
    echo "$body" | jq '.' 2>/dev/null || echo "$body"
  fi
  echo ""
else
  echo "Job completed but no results available yet"
  echo ""
  if [ "$2" == "--json" ]; then
    echo "$body" | jq '.' 2>/dev/null || echo "$body"
  fi
  echo ""
fi

echo "════════════════════════════════════════════════════════════════"
