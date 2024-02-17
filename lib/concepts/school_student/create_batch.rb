# frozen_string_literal: true

require 'roo'

module SchoolStudent
  class CreateBatch
    class << self
      def call(school:, uploaded_file:, token:)
        response = OperationResponse.new
        create_batch(school, uploaded_file, token)
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error creating school students: #{e}"
        response
      end

      private

      def create_batch(school, uploaded_file, token)
        sheet = Roo::Spreadsheet.open(uploaded_file.tempfile).sheet(0)

        validate(school:, sheet:)

        non_header_rows_with_content(sheet:).each do |name, username, password|
          ProfileApiClient.create_school_student(token:, username:, password:, name:, organisation_id: school.id)
        end
      end

      def validate(school:, sheet:)
        expected_header = ['Student Name', 'Username', 'Password']

        raise ArgumentError, 'school is not verified' unless school.verified_at
        raise ArgumentError, 'the spreadsheet header row is invalid' unless sheet.row(1) == expected_header

        @errors = []

        non_header_rows_with_content(sheet:).each do |name, username, password|
          validate_row(name:, username:, password:)
        end

        raise ArgumentError, @errors.join(', ') if @errors.any?
      end

      def validate_row(name:, username:, password:)
        @errors.push("name '#{name}' is invalid") if name.blank?
        @errors.push("username '#{username}' is invalid") if username.blank?
        @errors.push("password '#{password}' is invalid") if password.blank? || password.size < 8
      end

      def non_header_rows_with_content(sheet:)
        Enumerator.new do |yielder|
          (2..sheet.last_row).each do |i|
            name, username, password = sheet.row(i)

            next if name.blank? && username.blank? && password.blank?

            yielder.yield [name, username, password]
          end
        end
      end
    end
  end
end
