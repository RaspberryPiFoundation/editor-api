#!/bin/bash
# School Import Script
# Usage: ./scripts/import.sh <path_to_csv_file>

set -e

# Check if CSV file path is provided
if [ -z "$1" ]; then
  echo "Error: CSV file path required"
  echo "Usage: $0 <path_to_csv_file>"
  echo "Example: $0 docs/import/school_import_template.csv"
  exit 1
fi

# Check if file exists
if [ ! -f "$1" ]; then
  echo "Error: File not found: $1"
  exit 1
fi

# Check if TOKEN is set
if [ -z "$TOKEN" ]; then
  echo "Error: TOKEN environment variable not set"
  echo "Please set TOKEN before running:"
  echo "  export TOKEN='your_token_here'"
  exit 1
fi

CSV_FILE="$1"
API_URL="${API_URL:-http://localhost:3009/api/schools/import}"

# Count schools in CSV (excluding header)
school_count=$(( $(wc -l < "$CSV_FILE") - 1 ))

echo "════════════════════════════════════════════════════════════════"
echo "  School Import"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "CSV File:        $CSV_FILE"
echo "Schools to Import: $school_count"
echo "API URL:         $API_URL"
echo ""
echo "Starting import..."
echo ""

# Make the API call
response=$(curl -sS -X POST "$API_URL" \
  -H "Authorization: $TOKEN" \
  -F "csv_file=@$CSV_FILE" \
  -w "\n%{http_code}")

# Extract HTTP status code (last line)
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

# Check response
if [ "$http_code" -eq 202 ]; then
  echo "════════════════════════════════════════════════════════════════"
  echo "  ✓ Import Job Started Successfully"
  echo "════════════════════════════════════════════════════════════════"
  echo ""
  
  # Parse JSON response
  job_id=$(echo "$body" | jq -r '.job_id' 2>/dev/null)
  total_schools=$(echo "$body" | jq -r '.total_schools' 2>/dev/null)
  message=$(echo "$body" | jq -r '.message' 2>/dev/null)
  
  if [ -n "$job_id" ] && [ "$job_id" != "null" ]; then
    echo "Job ID:          $job_id"
    echo "Total Schools:   $total_schools"
    echo "Status:          $message"
    echo ""
    echo "────────────────────────────────────────────────────────────────"
    echo "  Next Steps"
    echo "────────────────────────────────────────────────────────────────"
    echo ""
    echo "Check import status with:"
    echo "  ./scripts/status.sh $job_id"
    echo ""
    echo "Or manually with curl:"
    echo "  curl -sS -H \"Authorization: \$TOKEN\" \\"
    echo "    http://localhost:3009/api/school_import_jobs/$job_id | jq '.'"
    echo ""
  else
    # Fallback if parsing fails
    echo "$body" | jq '.' 2>/dev/null || echo "$body"
    echo ""
  fi
  
  echo "════════════════════════════════════════════════════════════════"
  
else
  echo "════════════════════════════════════════════════════════════════"
  echo "  ✗ Import Failed (HTTP $http_code)"
  echo "════════════════════════════════════════════════════════════════"
  echo ""
  
  # Try to parse error message
  error_code=$(echo "$body" | jq -r '.error_code' 2>/dev/null)
  error_message=$(echo "$body" | jq -r '.message' 2>/dev/null)
  
  if [ -n "$error_code" ] && [ "$error_code" != "null" ]; then
    echo "Error Code:      $error_code"
    echo "Message:         $error_message"
    echo ""
    
    # Show details if available
    has_details=$(echo "$body" | jq 'has("details")' 2>/dev/null)
    if [ "$has_details" == "true" ]; then
      echo "Details:"
      echo "$body" | jq '.details' 2>/dev/null
      echo ""
    fi
  else
    # Fallback if not structured error
    echo "$body" | jq '.' 2>/dev/null || echo "$body"
    echo ""
  fi
  
  echo "════════════════════════════════════════════════════════════════"
  exit 1
fi
