# School Import Quick Reference for Customer Success Managers

## Prerequisites

1. School owners must have existing Code Editor for Education accounts.
3. School owners must be unique within the CSV, and in the existing database.
4. CSV file must be properly formatted (see template)

## Step-by-Step Process

### 1. Prepare the CSV File

Download the template from the admin interface.

Required columns:
- `name` - School name
- `website` - School website URL (e.g., https://example.edu)
- `address_line_1` - Street address
- `municipality` - City/town
- `country_code` - 2-letter code (US, GB, CA, etc.)
- `owner_email` - Email of school owner (must exist in Profile)

Optional columns:
- `address_line_2` - Additional address info
- `administrative_area` - State/province
- `postal_code` - ZIP/postal code
- `reference` - School reference number (must be unique if provided)

### 2. Validate Owner Emails

Before importing, verify that all owner emails in your CSV correspond to existing accounts in Code Editor for Education. Owners without accounts will cause those schools to fail during import, but schools with correct owners will succeed.

### 3. Upload the CSV

Visit the `/admin` page and select **School Import Results**. On this page, click the **New Import** button.

On the following page, you can click **Choose file** to select a CSV, then choose **Upload and Start Import** to import the CSV.

### 4. Track Progress

You can refresh the **School Import Results** page to see the status of your upload. It should not take very long to complete.

### 5. Review Results

On the **School Import Results** page, any administrator can see the history of successful uploads and inspect any particular upload. A brief summary of the number of schools that succeeded and failed is shown in the table.

Click on a row in the table to inspect an upload futher. In the following page, you can also download a CSV of the results which will include the system-generated school code.

### 6. Handle Failures

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

The system validates the entire CSV before starting the import. If validation fails, you'll receive an error immediately on the upload page.

To fix:
1. Check that all required headers are present (case-sensitive)
2. Verify all required fields have values for every row
3. Check country codes are valid 2-letter codes (US not USA)
4. Verify website URLs are properly formatted (must include https://)
5. Look for the row number in the error details

### Import Succeeds But Some Schools Failed

This is normal - the system processes all schools it can. Review the failed list and address issues individually.

### Duplicate Owner Emails in CSV

If your CSV contains the same owner email more than once, the import will be rejected before processing.

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
