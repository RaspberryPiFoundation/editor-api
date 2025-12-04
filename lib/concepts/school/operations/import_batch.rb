# frozen_string_literal: true

class School
  class ImportBatch
    REQUIRED_FIELDS = %i[name website address_line_1 municipality country_code owner_email].freeze

    class << self
      def call(csv_file:, current_user:)
        response = OperationResponse.new

        parsed_schools = parse_csv(csv_file)

        if parsed_schools[:error]
          response[:error] = parsed_schools[:error]
          return response
        end

        # Check for duplicate owner emails in the CSV
        duplicate_check = check_duplicate_owners(parsed_schools[:schools])
        if duplicate_check[:error]
          response[:error] = duplicate_check[:error]
          return response
        end

        job = enqueue_import_job(
          schools_data: parsed_schools[:schools],
          current_user: current_user
        )

        response[:job_id] = job.job_id
        response[:total_schools] = parsed_schools[:schools].length
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = SchoolImportError.format_error(:unknown_error, e.message)
        response
      end

      private

      def check_duplicate_owners(schools)
        owner_emails = schools.filter_map { |s| s[:owner_email]&.strip&.downcase }
        duplicates = owner_emails.select { |e| owner_emails.count(e) > 1 }.uniq

        if duplicates.any?
          error = SchoolImportError.format_error(
            :duplicate_owner_email,
            'Duplicate owner emails found in CSV',
            { duplicate_emails: duplicates }
          )
          return { error: error }
        end

        {}
      end

      def parse_csv(csv_file)
        require 'csv'

        csv_content = csv_file.read
        return { error: SchoolImportError.format_error(:csv_invalid_format, 'CSV file is empty') } if csv_content.blank?

        csv_data = CSV.parse(csv_content, headers: true, header_converters: :symbol)

        if csv_data.headers.nil? || !valid_headers?(csv_data.headers)
          return {
            error: SchoolImportError.format_error(
              :csv_invalid_format,
              'Invalid CSV format. Required headers: name, website, address_line_1, municipality, country_code, owner_email'
            )
          }
        end

        process_csv_rows(csv_data)
      rescue CSV::MalformedCSVError => e
        { error: SchoolImportError.format_error(:csv_malformed, "Invalid CSV file format: #{e.message}") }
      rescue StandardError => e
        Sentry.capture_exception(e)
        { error: SchoolImportError.format_error(:unknown_error, "Failed to parse CSV: #{e.message}") }
      end

      def process_csv_rows(csv_data)
        schools = []
        errors = []

        csv_data.each_with_index do |row, index|
          row_number = index + 2 # +2 because index starts at 0 and we skip header row
          school_data = row.to_h

          validation_errors = validate_school_data(school_data, row_number)
          if validation_errors
            errors << validation_errors
            next
          end

          schools << school_data
        end

        if errors.any?
          { error: SchoolImportError.format_row_errors(errors) }
        else
          { schools: schools }
        end
      end

      def valid_headers?(headers)
        REQUIRED_FIELDS.all? { |h| headers.include?(h) }
      end

      def validate_school_data(data, row_number)
        errors = []

        # Strip whitespace from all string fields
        data.each do |key, value|
          data[key] = value.strip if value.is_a?(String)
        end

        # Validate required fields
        REQUIRED_FIELDS.each do |field|
          errors << { field: field.to_s, message: 'is required' } if data[field].blank?
        end

        # Validate field formats
        validate_country_code(data, errors)
        validate_website_format(data, errors)
        validate_email_format(data, errors)

        return nil if errors.empty?

        { row: row_number, errors: errors }
      end

      def validate_country_code(data, errors)
        return if data[:country_code].blank?
        return if ISO3166::Country.codes.include?(data[:country_code].upcase)

        errors << { field: 'country_code', message: "invalid code: #{data[:country_code]}" }
      end

      def validate_website_format(data, errors)
        return if data[:website].blank?
        return if data[:website].match?(School::VALID_URL_REGEX)

        errors << { field: 'website', message: 'invalid format' }
      end

      def validate_email_format(data, errors)
        return if data[:owner_email].blank?
        return if data[:owner_email].match?(URI::MailTo::EMAIL_REGEXP)

        errors << { field: 'owner_email', message: 'invalid email format' }
      end

      def enqueue_import_job(schools_data:, current_user:)
        SchoolImportJob.perform_later(
          schools_data: schools_data,
          user_id: current_user.id,
          token: current_user.token
        )
      end
    end
  end
end
