# frozen_string_literal: true

class Ability
  include CanCan::Ability

  # rubocop:disable Metrics/AbcSize
  def initialize(user)
    can :show, Project, user_id: nil
    can :show, Component, project: { user_id: nil }
    can :read, Lesson, visibility: 'public'

    return unless user

    can %i[read create update destroy], Project, user_id: user.id
    can %i[read create update destroy], Component, project: { user_id: user.id }

    can :create, School # The user agrees to become a school-owner by creating a school.
    can :create, Lesson, school_id: nil, school_class_id: nil
    can %i[read update], Lesson, user_id: user.id

    user.organisation_ids.each do |organisation_id|
      define_school_owner_abilities(organisation_id:) if user.school_owner?(organisation_id:)
      define_school_teacher_abilities(user:, organisation_id:) if user.school_teacher?(organisation_id:)
      define_school_student_abilities(user:, organisation_id:) if user.school_student?(organisation_id:)
    end
  end
  # rubocop:enable Metrics/AbcSize

  private

  def define_school_owner_abilities(organisation_id:)
    can(%i[read update destroy], School, id: organisation_id)
    can(%i[read create update destroy], SchoolClass, school: { id: organisation_id })
    can(%i[read create destroy], ClassMember, school_class: { school: { id: organisation_id } })
    can(%i[read create destroy], :school_owner)
    can(%i[read create destroy], :school_teacher)
    can(%i[read create create_batch update destroy], :school_student)
    can(%i[create], Lesson, school_id: organisation_id)
    can(%i[read update], Lesson, school_id: organisation_id, visibility: %w[teachers students])
    can(%i[update], Lesson, school_id: organisation_id, visibility: 'public')
  end

  def define_school_teacher_abilities(user:, organisation_id:)
    can(%i[read], School, id: organisation_id)
    can(%i[create], SchoolClass, school: { id: organisation_id })
    can(%i[read update destroy], SchoolClass, school: { id: organisation_id }, teacher_id: user.id)
    can(%i[read create destroy], ClassMember, school_class: { school: { id: organisation_id }, teacher_id: user.id })
    can(%i[read], :school_owner)
    can(%i[read], :school_teacher)
    can(%i[read create create_batch update], :school_student)
    can(%i[create], Lesson) { |lesson| school_teacher_can_create_lesson?(user:, organisation_id:, lesson:) }
    can(%i[read], Lesson, school_id: organisation_id, visibility: %w[teachers students])
  end

  # rubocop:disable Layout/LineLength
  def define_school_student_abilities(user:, organisation_id:)
    can(%i[read], School, id: organisation_id)
    can(%i[read], SchoolClass, school: { id: organisation_id }, members: { student_id: user.id })
    can(%i[read], Lesson, school_id: organisation_id, visibility: 'students', school_class: { members: { student_id: user.id } })
  end
  # rubocop:enable Layout/LineLength

  def school_teacher_can_create_lesson?(user:, organisation_id:, lesson:)
    is_my_lesson = lesson.school_id == organisation_id && lesson.user_id == user.id
    is_my_class = lesson.school_class && lesson.school_class.teacher_id == user.id

    is_my_lesson && (is_my_class || !lesson.school_class)
  end
end
