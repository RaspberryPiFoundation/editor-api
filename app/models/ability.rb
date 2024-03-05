# frozen_string_literal: true

class Ability
  include CanCan::Ability

  # rubocop:disable Metrics/AbcSize
  def initialize(user)
    # Anyone can view projects not owner by a user or a school.
    can :show, Project, user_id: nil, school_id: nil
    can :show, Component, project: { user_id: nil, school_id: nil }

    # Anyone can read publicly shared lessons.
    can :read, Lesson, visibility: 'public'

    return unless user

    # Any authenticated user can create projects not owned by a school.
    can :create, Project, user_id: user.id, school_id: nil
    can :create, Component, project: { user_id: user.id, school_id: nil }

    # Any authenticated user can manage their own projects.
    can %i[read update destroy], Project, user_id: user.id
    can %i[read update destroy], Component, project: { user_id: user.id }

    # Any authenticated user can create a school. They agree to become the school-owner.
    can :create, School

    # Any authenticated user can create a lesson, to support a RPF library of public lessons.
    can :create, Lesson, school_id: nil, school_class_id: nil

    # Any authenticated user can create a copy of a publicly shared lesson.
    can :create_copy, Lesson, visibility: 'public'

    # Any authenticated user can manage their own lessons.
    can %i[read create_copy update destroy], Lesson, user_id: user.id

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
    can(%i[create create_copy], Lesson, school_id: organisation_id)
    can(%i[read update destroy], Lesson, school_id: organisation_id, visibility: %w[teachers students public])
    can(%i[create], Project, school_id: organisation_id)
  end

  def define_school_teacher_abilities(user:, organisation_id:)
    can(%i[read], School, id: organisation_id)
    can(%i[create], SchoolClass, school: { id: organisation_id })
    can(%i[read update destroy], SchoolClass, school: { id: organisation_id }, teacher_id: user.id)
    can(%i[read create destroy], ClassMember, school_class: { school: { id: organisation_id }, teacher_id: user.id })
    can(%i[read], :school_owner)
    can(%i[read], :school_teacher)
    can(%i[read create create_batch update], :school_student)
    can(%i[create destroy], Lesson) { |lesson| school_teacher_can_manage_lesson?(user:, organisation_id:, lesson:) }
    can(%i[read create_copy], Lesson, school_id: organisation_id, visibility: %w[teachers students])
    can(%i[create], Project) { |project| school_teacher_can_manage_project?(user:, organisation_id:, project:) }
  end

  # rubocop:disable Layout/LineLength
  def define_school_student_abilities(user:, organisation_id:)
    can(%i[read], School, id: organisation_id)
    can(%i[read], SchoolClass, school: { id: organisation_id }, members: { student_id: user.id })
    can(%i[read], Lesson, school_id: organisation_id, visibility: 'students', school_class: { members: { student_id: user.id } })
    can(%i[create], Project, school_id: organisation_id, user_id: user.id, lesson_id: nil)
  end
  # rubocop:enable Layout/LineLength

  def school_teacher_can_manage_lesson?(user:, organisation_id:, lesson:)
    is_my_lesson = lesson.school_id == organisation_id && lesson.user_id == user.id
    is_my_class = lesson.school_class && lesson.school_class.teacher_id == user.id

    is_my_lesson && (is_my_class || !lesson.school_class)
  end

  def school_teacher_can_manage_project?(user:, organisation_id:, project:)
    is_my_project = project.school_id == organisation_id && project.user_id == user.id
    is_my_lesson = project.lesson && project.lesson.user_id == user.id

    is_my_project && (is_my_lesson || !project.lesson)
  end
end
