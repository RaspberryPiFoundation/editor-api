# frozen_string_literal: true

module SchoolImportError
  CODES = {
    csv_invalid_format: 'CSV_INVALID_FORMAT',
    csv_malformed: 'CSV_MALFORMED',
    csv_validation_failed: 'CSV_VALIDATION_FAILED',
    owner_not_found: 'OWNER_NOT_FOUND',
    owner_already_creator: 'OWNER_ALREADY_CREATOR',
    owner_has_existing_role: 'OWNER_HAS_EXISTING_ROLE',
    duplicate_owner_email: 'DUPLICATE_OWNER_EMAIL',
    school_validation_failed: 'SCHOOL_VALIDATION_FAILED',
    job_not_found: 'JOB_NOT_FOUND',
    csv_file_required: 'CSV_FILE_REQUIRED',
    unknown_error: 'UNKNOWN_ERROR'
  }.freeze

  class << self
    def format_error(code, message, details = {})
      {
        error_code: CODES[code] || CODES[:unknown_error],
        message: message,
        details: details
      }.compact
    end

    def format_row_errors(errors_array)
      {
        error_code: CODES[:csv_validation_failed],
        message: 'CSV validation failed',
        details: {
          row_errors: errors_array
        }
      }
    end
  end
end
