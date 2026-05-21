# frozen_string_literal: true

# Computes the join "status" symbol that describes the relationship between
# `user` and `school_class` — the controller uses it to decide what HTTP
# response to return and whether to enrol the user.
#
# Possible return values:
#   :already_member       — user is already in this class
#   :owner                — user owns this school (redirect, no enrolment)
#   :joinable_as_teacher  — user teaches this school but isn't in the class
#   :joinable             — user can be enrolled as a student of this class
#   :not_a_student        — user has a non-student role in some other school
#   :wrong_school         — user is a student of a different school
#   :domain_mismatch      — user's email domain isn't registered for the school
class JoinStatusService
  def initialize(school:, school_class:, user:)
    @school = school
    @school_class = school_class
    @user = user
  end

  def call
    return :already_member if user_is_member_of_class?
    return existing_user_join_status if user_has_role_in_school?

    new_user_join_status
  end

  private

  # The user already has a role in this school: which one decides the status.
  def existing_user_join_status
    return :owner if user_is_owner_of_school?
    return :joinable_as_teacher if user_is_teacher_of_school?

    :joinable # student is the only remaining role for this school
  end

  # The user has no role in this school yet: may they join as a new student?
  def new_user_join_status
    return :not_a_student if user_has_non_student_role?
    return :wrong_school if user_in_different_school?
    return :domain_mismatch unless @school.email_domain_in_school_domains?(@user.email)

    :joinable
  end

  def user_is_member_of_class?
    ClassStudent.exists?(school_class: @school_class, student_id: @user.id) ||
      ClassTeacher.exists?(school_class: @school_class, teacher_id: @user.id)
  end

  def user_is_owner_of_school?
    Role.exists?(school: @school, user_id: @user.id, role: Role.roles[:owner])
  end

  def user_is_teacher_of_school?
    Role.exists?(school: @school, user_id: @user.id, role: Role.roles[:teacher])
  end

  def user_has_role_in_school?
    Role.exists?(school: @school, user_id: @user.id)
  end

  def user_has_non_student_role?
    Role.where(user_id: @user.id).where.not(role: Role.roles[:student]).exists?
  end

  def user_in_different_school?
    Role.where(user_id: @user.id).where.not(school_id: @school.id).exists?
  end
end
