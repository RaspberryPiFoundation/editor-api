# frozen_string_literal: true

class CreateStudentsJob < ApplicationJob
  class ConcurrencyExceededForSchool < StandardError; end

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

  def self.attempt_perform_later(school_id:, students:, token:, actor_user_id: nil)
    args = { school_id:, students:, token: }
    args[:actor_user_id] = actor_user_id if actor_user_id.present?

    perform_later(**args)
  end

  def perform(school_id:, students:, token:, actor_user_id: nil)
    school = School.find(school_id)
    decrypted_students = StudentHelpers.decrypt_students(students)
    SafeguardingFlagService.create_for_token(token:, school:)
    responses = ProfileApiClient.create_school_students(token:, students: decrypted_students, school_id:)
    return if responses[:created].blank?

    responses[:created].each do |user_id|
      Role.student.create!(school_id:, user_id:)
      track_student_created(school_id:, student_id: user_id, actor_user_id:)
    end
  end

  private

  def track_student_created(school_id:, student_id:, actor_user_id:)
    return if actor_user_id.blank?

    EventTracker.track!(
      name: 'Student - Created',
      user_id: actor_user_id,
      properties: {
        school_id:,
        student_id:
      }
    )
  end
end
