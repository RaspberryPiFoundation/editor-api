# frozen_string_literal: true

class SchoolImportJob < ApplicationJob
  retry_on StandardError, wait: :polynomially_longer, attempts: 3 do |_job, e|
    Sentry.capture_exception(e)
    raise e
  end

  queue_as :import_schools_job

  def perform(schools_data:, user_id:, token:)
    @token = token
    @results = {
      successful: [],
      failed: []
    }

    schools_data.map(&:with_indifferent_access).each do |school_data|
      import_school(school_data)
    end

    # Store results in dedicated table
    store_results(@results, user_id)

    @results
  end

  private

  def store_results(results, user_id)
    SchoolImportResult.create!(
      job_id: job_id,
      user_id: user_id,
      results: results
    )
  rescue StandardError => e
    Sentry.capture_exception(e)
    # Don't fail the job if we can't store results
  end

  def import_school(school_data)
    owner = find_owner(school_data[:owner_email])

    unless owner
      @results[:failed] << {
        name: school_data[:name],
        error_code: SchoolImportError::CODES[:owner_not_found],
        error: "Owner not found: #{school_data[:owner_email]}",
        owner_email: school_data[:owner_email]
      }
      return
    end

    # Check if this owner already has any role in any school
    existing_role = Role.find_by(user_id: owner[:id])
    if existing_role
      existing_school = existing_role.school
      @results[:failed] << {
        name: school_data[:name],
        error_code: SchoolImportError::CODES[:owner_has_existing_role],
        error: "Owner #{school_data[:owner_email]} already has a role in school '#{existing_school.name}'",
        owner_email: school_data[:owner_email],
        existing_school_id: existing_school.id
      }
      return
    end

    school_params = build_school_params(school_data)

    # Use transaction for atomicity
    School.transaction do
      result = School::Create.call(
        school_params: school_params,
        creator_id: owner[:id]
      )

      if result.success?
        school = result[:school]

        # Auto-verify the imported school using the verification service
        SchoolVerificationService.new(school).verify(token: @token)

        @results[:successful] << {
          name: school.name,
          id: school.id,
          code: school.code,
          owner_email: school_data[:owner_email]
        }
      else
        @results[:failed] << {
          name: school_data[:name],
          error_code: SchoolImportError::CODES[:school_validation_failed],
          error: format_errors(result[:error]),
          owner_email: school_data[:owner_email]
        }
      end
    end
  rescue StandardError => e
    @results[:failed] << {
      name: school_data[:name],
      error_code: SchoolImportError::CODES[:unknown_error],
      error: e.message,
      owner_email: school_data[:owner_email]
    }
    Sentry.capture_exception(e)
  end

  def find_owner(email)
    return nil if email.blank?

    UserInfoApiClient.find_user_by_email(email)
  rescue StandardError => e
    Sentry.capture_exception(e)
    nil
  end

  def build_school_params(school_data)
    {
      name: school_data[:name],
      website: school_data[:website],
      address_line_1: school_data[:address_line_1],
      address_line_2: school_data[:address_line_2],
      municipality: school_data[:municipality],
      administrative_area: school_data[:administrative_area],
      postal_code: school_data[:postal_code],
      country_code: school_data[:country_code]&.upcase,
      reference: school_data[:reference],
      creator_agree_authority: true,
      creator_agree_terms_and_conditions: true,
      creator_agree_responsible_safeguarding: true,
      user_origin: 'experience_cs'
    }.compact
  end

  def format_errors(errors)
    return errors.to_s unless errors.respond_to?(:full_messages)

    errors.full_messages.join(', ')
  end
end
