# frozen_string_literal: true

class ConcurrencyExceededForSchool < StandardError; end

class CreateStudentsJob < ApplicationJob
  retry_on StandardError, attempts: 3 do |_job, e|
    Sentry.capture_exception(e)
    raise e
  end

  # Don't retry...
  rescue_from ConcurrencyExceededForSchool do |e|
    Rails.logger.error "Only one job per school can be enqueued at a time: #{school_id}"
    Sentry.capture_exception(e)
    raise e
  end

  # Don't retry...
  rescue_from ActiveRecord::RecordInvalid do |e|
    Rails.logger.error "Failed to create student role: #{e.record.errors.full_messages.join(', ')}"
    Sentry.capture_exception(e)
    raise e
  end

  include GoodJob::ActiveJobExtensions::Concurrency

  queue_as :default

  # Restrict to one job per school to avoid duplicates
  good_job_control_concurrency_with(
    key: -> { "create_students_job_#{arguments.first[:school_id]}" },
    total_limit: 1
  )

  def self.attempt_perform_later(school_id:, students:, token:, user_id:)
    concurrency_key = "create_students_job_#{school_id}"
    existing_jobs = GoodJob::Job.where(concurrency_key:, finished_at: nil)

    raise ConcurrencyExceededForSchool, 'Only one job per school can be enqueued at a time.' if existing_jobs.exists?

    ActiveRecord::Base.transaction do
      job = perform_later(school_id:, students:, token:)
      UserJob.create!(user_id:, good_job_id: job.job_id) unless job.nil?

      job
    end
  end

  def perform(school_id:, students:, token:)
    students.each { |student| student[:password] = DecryptionHelpers.decrypt_password(student[:password]) }
    responses = ProfileApiClient.create_school_students(token:, students:, school_id:)
    return if responses[:created].blank?

    responses[:created].each do |user_id|
      Role.student.create!(school_id:, user_id:)
    end
  end
end
