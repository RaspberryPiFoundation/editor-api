# frozen_string_literal: true

class ConcurrencyExceededForSchool < StandardError; end

class CreateStudentsJob < ApplicationJob
  retry_on StandardError, wait: :polynomially_longer, attempts: 3 do |_job, e|
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

  queue_as :create_students_job

  def self.attempt_perform_later(school_id:, students:, token:)
    perform_later(school_id:, students:, token:)
  end

  def perform(school_id:, students:, token:)
    decrypted_students = students.map do |student|
      {
        name: student[:name],
        username: student[:username],
        password: DecryptionHelpers.decrypt_password(student[:password])
      }
    end

    responses = ProfileApiClient.create_school_students(token:, students: decrypted_students, school_id:)
    return if responses[:created].blank?

    responses[:created].each do |user_id|
      Role.student.create!(school_id:, user_id:)
    end
  end
end
