# School Import Quick Reference for Customer Success Managers

## Prerequisites

1. You must have the `experience-cs-admin` or `profile-admin` role in Editor-API.
2. School owners must have existing Code Editor for Education accounts.
3. School owners must be unique within the CSV, and in the existing database.
4. CSV file must be properly formatted (see template)

## Step-by-Step Process

### 1. Prepare the CSV File

Download the template: `docs/import/school_import_template.csv`

Required columns:
- `name` - School name
- `website` - School website URL (e.g., https://example.edu)
- `address_line_1` - Street address
- `municipality` - City/town
- `country_code` - 2-letter code (US, GB, CA, etc.)
- `owner_email` - Email of school owner (must exist in system)

Optional columns:
- `address_line_2` - Additional address info
- `administrative_area` - State/province
- `postal_code` - ZIP/postal code
- `reference` - School reference number (must be unique)

### 2. Validate Owner Emails

Before importing, verify that all owner emails in your CSV correspond to existing accounts in Code Editor for Education. Owners without accounts will cause those schools to fail during import.

### 3. Upload the CSV

**Prerequisite**

In order to use the scripts, you have to have an OAuth token from `editor-api`.

TODO: Explain how to get such a token, or write a tool to do it.

You can supply this token to the scripts mentioned below by:

```bash
export TOKEN=ory_ac_a2i-3ayKjE_8YcGqRlGXdaKrZ4yWkSdfG6vwQmLEsMg.bUdeff5re2vDLd6kRffaGp8NNX6ry8Yzm7wf7aaMKWM
```

Obviously, don't use this value - use your own.

**Via API:**

```bash
curl -X POST https://editor-api.raspberrypi.org/api/schools/import \
  -H "Authorization: YOUR_TOKEN" \
  -F "csv_file=@path/to/schools.csv"
```

**Response:**
```json
{
  "job_id": "550e8400-e29b-41d4-a716-446655440000",
  "total_schools": 150,
  "message": "Import job started successfully"
}
```

**Via Script:**

```bash
$ $scripts/import.sh ./docs/import/school_import_template.csv
════════════════════════════════════════════════════════════════
  School Import
════════════════════════════════════════════════════════════════

CSV File:        ./docs/import/school_import_template.csv
Schools to Import: 3
API URL:         http://localhost:3009/api/schools/import

Starting import...

════════════════════════════════════════════════════════════════
  ✓ Import Job Started Successfully
════════════════════════════════════════════════════════════════

Job ID:          8a24adf7-c705-451a-8bb3-051ec5d8fdd8
Total Schools:   3
Status:          Import job started successfully

────────────────────────────────────────────────────────────────
  Next Steps
────────────────────────────────────────────────────────────────

Check import status with:
  ./scripts/status.sh 8a24adf7-c705-451a-8bb3-051ec5d8fdd8

Or manually with curl:
  curl -sS -H "Authorization: $TOKEN" \
    http://localhost:3009/api/school_import_jobs/8a24adf7-c705-451a-8bb3-051ec5d8fdd8 | jq '.'
```

### 4. Track Progress

Use the job_id from the response:

**Via API**

```bash
curl https://editor-api.raspberrypi.org/api/school_import_jobs/550e8400-e29b-41d4-a716-446655440000 \
  -H "Authorization: YOUR_TOKEN"
```

**Response while running:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "running",
  "created_at": "2024-01-15T10:00:00Z",
  "finished_at": null,
  "job_class": "ImportSchoolsJob"
}
```

**Response when completed:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "completed",
  "created_at": "2024-01-15T10:00:00Z",
  "finished_at": "2024-01-15T10:05:00Z",
  "job_class": "ImportSchoolsJob",
  "results": {
    "successful": [...],
    "failed": [...]
  }
}
```

**Via Script**

```bash
[f@rpi] ➜ editor-api (U!@ fs-implement-school-import-endpoint) ./scripts/status.sh 8a24adf7-c705-451a-8bb3-051ec5d8fdd8
════════════════════════════════════════════════════════════════
  School Import Job Status
════════════════════════════════════════════════════════════════

Job ID:      8a24adf7-c705-451a-8bb3-051ec5d8fdd8
Status:      completed
Job Type:    ImportSchoolsJob
Created:     2025-11-20T15:44:52.925Z
Finished:    2025-11-20T15:44:53.316Z

════════════════════════════════════════════════════════════════
  Summary
════════════════════════════════════════════════════════════════

Total Schools:    3
✓ Successful:     3
✗ Failed:         0

════════════════════════════════════════════════════════════════
  Successful Schools
════════════════════════════════════════════════════════════════

NAME                                     CODE         OWNER EMAIL
────────────────────────────────────────────────────────────────
Springfield Elementary School            85-59-21     principal@springfield-elem.edu
Shelbyville High School                  76-79-30     admin@shelbyville-high.edu
Capital City Academy                     32-91-93     headteacher@capital-city-academy.edu

════════════════════════════════════════════════════════════════
```

### 5. Handle Failures

Common failure reasons and solutions:

| Error Code | Error Message | Solution |
|------------|---------------|----------|
| `OWNER_NOT_FOUND` | Owner not found: email@example.com | Verify owner has CEfE account, create if needed |
| `OWNER_ALREADY_CREATOR` | Owner is already the creator of school 'X' | Each person can only create one school; use different owner |
| `SCHOOL_VALIDATION_FAILED` | Validation errors | Check country code, website format, required fields |
| `CSV_VALIDATION_FAILED` | CSV validation failed | Check error details for specific row and field errors |
| `DUPLICATE_OWNER_EMAIL` | Duplicate owner emails found in CSV | Same owner email appears multiple times - only one school per owner allowed |

For failed schools, you can either:
1. Fix the issues and re-import (only failed schools)
2. Create them manually through the standard process

## Important Notes

- **Automatic Verification**: Imported schools are automatically verified and receive school codes
- **Owner Roles**: Owner roles are automatically created
- **One Owner Per School**: Each owner can only create one school (enforced at database level)
- **No Duplicate Owners in CSV**: The CSV cannot contain the same owner email multiple times
- **No Teacher Creation**: Teachers are NOT created during import - they must be invited separately
- **Country Codes**: Use ISO 3166-1 alpha-2 codes (find at https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)
- **Structured Errors**: All errors include error codes for programmatic handling

## Common Country Codes

| Country | Code |
|---------|------|
| United States | US |
| United Kingdom | GB |
| Canada | CA |
| Mexico | MX |

## Troubleshooting

### CSV Validation Fails Immediately

The system validates the entire CSV before starting the import. If validation fails, you'll receive a structured error response:

**Example Error Response:**
```json
{
  "error_code": "CSV_VALIDATION_FAILED",
  "message": "CSV validation failed",
  "details": {
    "row_errors": [
      {
        "row": 2,
        "errors": [
          {"field": "country_code", "message": "invalid code: USA"}
        ]
      },
      {
        "row": 5,
        "errors": [
          {"field": "website", "message": "invalid format"}
        ]
      }
    ]
  }
}
```

To fix:
1. Check that all required headers are present (case-sensitive)
2. Verify all required fields have values for every row
3. Check country codes are valid 2-letter codes (US not USA)
4. Verify website URLs are properly formatted (must include https://)
5. Look for the row number in the error details

### Import Succeeds But Some Schools Failed

This is normal - the system processes all schools it can. Review the failed list and address issues individually.

### Duplicate Owner Emails in CSV

If your CSV contains the same owner email more than once, the import will be rejected before processing:

**Error Response:**
```json
{
  "error_code": "DUPLICATE_OWNER_EMAIL",
  "message": "Duplicate owner emails found in CSV",
  "details": {
    "duplicate_emails": ["admin@example.edu"]
  }
}
```

**Solution**: Each owner can only create one school. Either:
- Use different owner emails for each school
- Have one owner create their school first, then import the rest
- Remove duplicate entries and import in batches

### All Schools Failed

Common causes:
- Owner emails don't match any accounts
- CSV formatting issues
- Network/system errors (check with technical team)

## Getting Help

If you encounter issues:

1. Check the error message and error_code for specific details
2. Verify your CSV matches the template format
3. Confirm all owner emails are valid accounts
4. Ensure no duplicate owner emails in your CSV
5. Contact the technical team with:
   - The job_id
   - The CSV file (or sample rows)
   - Error codes and messages received

## Example Workflow

**Scenario**: Import 150 schools for Springfield School District

1. District admin provides school information
2. You create CSV with all 150 schools
3. Verify all 150 owners have accounts (or help them create accounts)
4. Upload CSV via API
5. Wait for job to complete (~2-5 minutes for 150 schools)
6. Review results: 148 succeeded, 2 failed
7. Fix issues with 2 failed schools (duplicate references)
8. Create those 2 schools manually or re-import
9. Notify district admin that all schools are ready and supply the generated codes
10. District admin can now invite teachers to their schools
