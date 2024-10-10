# frozen_string_literal: true

require 'awesome_print'

class ConcurrencyExceededForSchool < StandardError; end

class CreateStudentsJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  queue_as :default

  # Restrict to one job per school to avoid duplicates
  good_job_control_concurrency_with(
    key: -> { "create_students_job_#{arguments.first[:school_id]}" },
    total_limit: 1
  )

  # We need to raise an error if there is already a job running for the school
  def self.attempt_perform_later(school_id:, students:, token:)
    concurrency_key = "create_students_job_#{school_id}"
    existing_jobs = GoodJob::Job.where(concurrency_key:, finished_at: nil)

    raise ConcurrencyExceededForSchool, 'Only one job per school can be enqueued at a time.' if existing_jobs.exists?

    perform_later(school_id:, students:, token:)
  end

  def perform(school_id:, students:, token:)
    students = Array(students)
    responses = ProfileApiClient.create_school_students(token:, students:, school_id:)
    responses[:created].each do |user_id|
      Role.student.create!(school_id:, user_id:)
    end
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

  retry_on StandardError, attempts: 3 do |_job, e|
    Sentry.capture_exception(e)
    raise e
  end
end
