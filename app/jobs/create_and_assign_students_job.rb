# frozen_string_literal: true

class CreateAndAssignStudentsJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  BATCH_SIZE = 20

  good_job_concurrency_rule(
    label: -> { "create-and-assign-students-school-#{arguments.first[:school_class_id]}" },
    apply_label: true,
    perform_limit: 1
  )

  def self.enqueue_batches(school_class:, students:, current_user:)
    school = school_class.school
    SafeguardingFlagService.create_for_school_roles(user: current_user, school:)
    students = StudentHelpers.normalise_nil_values_to_empty_strings(students)
    @batch = GoodJob::Batch.new(description: "Creating and assigning students for #{school_class.school.name}")
    @batch.add do
      students.each_slice(BATCH_SIZE) do |student_batch|
        CreateAndAssignStudentsJob.perform_later(
          school_class_id: school_class.id,
          students: student_batch,
          creator_id: current_user.id,
          token: current_user.token
        )
      end
    end

    @batch.enqueue
    UserJob.create!(user_id: current_user.id, good_job_batch_id: @batch.id)
    @batch
  end

  def perform(school_class_id:, students:, creator_id:, token:)
    school_class = SchoolClass.find(school_class_id)
    responses = ProfileApiClient.create_school_students_sso(token:, students: students, school_id: school_class.school_id)

    successful_responses, failed_responses = responses.partition { |response| response[:success] }

    create_student_roles(school: school_class.school, students: successful_responses, creator_id: creator_id)
    create_class_students(school_class:, students: successful_responses, creator_id: creator_id)

    report_failures(failed_responses)
  end

  def create_student_roles(school:, students:, creator_id:)
    students.each do |student|
      Role.create_student_with_tracking!(school: school, creator_id:, student_id: student[:id])
    end
  end

  def create_class_students(school_class:, students:, creator_id:)
    students.each do |student|
      ClassStudent.create_with_tracking!(school_class: school_class, student_id: student[:id], creator_id: creator_id)
    end
  end

  def report_failures(responses)
    responses.each do |response|
      Sentry.capture_message('Student creation failed in Profile', extra: response[:error])
    end
  end
end
