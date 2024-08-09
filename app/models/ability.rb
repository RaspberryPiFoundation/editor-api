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

    # An unverified school owner can read their own school.
    can :read, School, creator_id: user.id, verified_at: nil

    # Any authenticated user can create a lesson, to support a RPF library of public lessons.
    can :create, Lesson, school_id: nil, school_class_id: nil

    # Any authenticated user can create a copy of a publicly shared lesson.
    can :create_copy, Lesson, visibility: 'public'

    # Any authenticated user can manage their own lessons.
    can %i[read create_copy update destroy], Lesson, user_id: user.id

    user.schools.each do |school|
      define_school_student_abilities(user:, school:) if user.school_student?(school)
      define_school_teacher_abilities(user:, school:) if user.school_teacher?(school)
      define_school_owner_abilities(school:) if user.school_owner?(school)
    end
  end
  # rubocop:enable Metrics/AbcSize

  private

  def define_school_owner_abilities(school:)
    can(%i[read update destroy], School, id: school.id)
    can(%i[read create update destroy], SchoolClass, school: { id: school.id })
    can(%i[read], Project, school_id: school.id, lesson: { visibility: %w[teachers students] })
    can(%i[read create create_batch destroy], ClassMember, school_class: { school: { id: school.id } })
    can(%i[read create destroy], :school_owner)
    can(%i[read create destroy], :school_teacher)
    can(%i[read create create_batch update destroy], :school_student)
    can(%i[create create_copy], Lesson, school_id: school.id)
    can(%i[read update destroy], Lesson, school_id: school.id, visibility: %w[teachers students public])
    can(%i[create], Project, school_id: school.id)
  end

  # rubocop:disable Metrics/AbcSize
  def define_school_teacher_abilities(user:, school:)
    can(%i[read], School, id: school.id)
    can(%i[create], SchoolClass, school: { id: school.id })
    can(%i[read update destroy], SchoolClass, school: { id: school.id }, teacher_id: user.id)
    can(%i[read create create_batch destroy], ClassMember,
        school_class: { school: { id: school.id }, teacher_id: user.id })
    can(%i[read], :school_owner)
    can(%i[read], :school_teacher)
    can(%i[read create create_batch update], :school_student)
    can(%i[create destroy], Lesson) do |lesson|
      school_teacher_can_manage_lesson?(user:, school:, lesson:)
    end
    can(%i[read create_copy], Lesson, school_id: school.id, visibility: %w[teachers students])
    can(%i[create], Project) do |project|
      school_teacher_can_manage_project?(user:, school:, project:)
    end
    can(%i[read], Project, school_id: school.id, lesson: { visibility: %w[teachers students] })
    can(%i[read], Project,
        remixed_from_id: Project.where(user_id: user.id, school_id: school.id, remixed_from_id: nil).pluck(:id))
  end
  # rubocop:enable Metrics/AbcSize

  # rubocop:disable Layout/LineLength
  def define_school_student_abilities(user:, school:)
    can(%i[read], School, id: school.id)
    can(%i[read], SchoolClass, school: { id: school.id }, members: { student_id: user.id })
    can(%i[read], Lesson, school_id: school.id, visibility: 'students', school_class: { members: { student_id: user.id } })
    can(%i[create], Project, school_id: school.id, user_id: user.id, lesson_id: nil)
    can(%i[read], Project, lesson: { school_id: school.id, school_class: { members: { student_id: user.id } } })
  end
  # rubocop:enable Layout/LineLength

  def school_student_can_read_project?(user:, lesson:, school:)
    lesson && lesson.school_id == school.id && lesson.school_class.members.exists?(student_id: user.id)
  end

  def school_teacher_can_manage_lesson?(user:, school:, lesson:)
    is_my_lesson = lesson.school_id == school.id && lesson.user_id == user.id
    is_my_class = lesson.school_class && lesson.school_class.teacher_id == user.id

    is_my_lesson && (is_my_class || !lesson.school_class)
  end

  def school_teacher_can_manage_project?(user:, school:, project:)
    is_my_project = project.school_id == school.id && project.user_id == user.id
    is_my_lesson = project.lesson && project.lesson.user_id == user.id

    is_my_project && (is_my_lesson || !project.lesson)
  end
end
