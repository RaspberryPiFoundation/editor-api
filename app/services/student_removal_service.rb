# frozen_string_literal: true

class StudentRemovalService
  class NoSchoolError < StandardError; end
  class NoClassesError < StandardError; end
  class StudentHasProjectsError < StandardError; end
  class NoopError < StandardError; end

  def initialize(school:, remove_from_profile: false, token: nil, raise_on_noop: false)
    @school = school
    @remove_from_profile = remove_from_profile
    @token = token
    @raise_on_noop = raise_on_noop
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def remove_student(student_id)
    raise NoSchoolError, 'School not found' if @school.nil?
    raise NoClassesError, 'School has no classes' if @school.classes.empty?
    raise StudentHasProjectsError, 'Student has existing projects' if Project.exists?(user_id: student_id)

    ActiveRecord::Base.transaction do
      roles_destroyed = remove_roles(student_id)
      classes_destroyed = remove_from_classes(student_id)
      remove_from_profile(student_id) if should_remove_from_profile?

      raise NoopError, 'Student has no roles or class assignments to remove' if roles_destroyed.zero? && classes_destroyed.zero? && should_raise_on_noop?
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  private

  def remove_from_classes(student_id)
    ClassStudent.where(
      school_class_id: @school.classes.pluck(:id),
      student_id: student_id
    ).destroy_all.length
  end

  def remove_roles(student_id)
    Role.student.where(
      user_id: student_id,
      school_id: @school.id
    ).destroy_all.length
  end

  def remove_from_profile(student_id)
    ProfileApiClient.delete_school_student(
      token: @token,
      school_id: @school.id,
      student_id: student_id
    )
  end

  def should_remove_from_profile?
    @remove_from_profile && @token.present?
  end

  def should_raise_on_noop?
    @raise_on_noop && !should_remove_from_profile?
  end
end
