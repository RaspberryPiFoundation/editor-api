# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    define_common_non_student_abilities(user)

    return unless user

    define_authenticated_non_student_abilities(user)
    user.schools.each do |school|
      define_school_student_abilities(user:, school:) if user.school_student?(school)
      define_school_teacher_abilities(user:, school:) if user.school_teacher?(school)
      define_school_owner_abilities(school:) if user.school_owner?(school)
    end

    define_experience_cs_admin_abilities(user)
  end

  private

  def define_common_non_student_abilities(user)
    return if user&.student?

    # Anyone can view projects not owned by a user or a school.
    can :show, Project, user_id: nil, school_id: nil
    can :show, Component, project: { user_id: nil, school_id: nil }

    # Anyone can read publicly shared lessons.
    can :read, Lesson, visibility: 'public'
  end

  def define_authenticated_non_student_abilities(user)
    return if user&.student?

    # Any authenticated user can create a school. They agree to become the school-owner.
    can :create, School

    # An unverified school owner can read their own school.
    can :read, School, creator_id: user.id, verified_at: nil

    # Any authenticated user can create a lesson, to support a RPF library of public lessons.
    can :create, Lesson, school_id: nil, school_class_id: nil

    # Any authenticated user can create a copy of a publicly shared lesson.
    can :create_copy, Lesson, visibility: 'public'

    # Any authenticated user can manage their own lessons.
    can %i[read create_copy update destroy], Lesson, user_id: user.id, school_id: nil

    # Any authenticated user can create projects not owned by a school.
    can :create, Project, user_id: user.id, school_id: nil
    can :create, Component, project: { user_id: user.id, school_id: nil }

    # Any authenticated user can manage their own projects.
    can %i[read update destroy], Project, user_id: user.id
    can %i[read update destroy], Component, project: { user_id: user.id }
  end

  def define_school_owner_abilities(school:)
    can(%i[read update destroy], School, id: school.id)
    can(%i[read], :school_member)
    can(%i[read create update destroy], SchoolClass, school: { id: school.id })
    can(%i[read show_context], Project, school_id: school.id, lesson: { visibility: %w[teachers students] })
    can(%i[read create create_batch destroy], ClassStudent, school_class: { school: { id: school.id } })
    can(%i[read create destroy], :school_owner)
    can(%i[read create destroy], :school_teacher)
    can(%i[read create create_batch update destroy], :school_student)
    can(%i[create create_copy], Lesson, school_id: school.id)
    can(%i[read update destroy], Lesson, school_id: school.id, visibility: %w[teachers students public])
  end

  def define_school_teacher_abilities(user:, school:)
    can(%i[read], School, id: school.id)
    can(%i[read], :school_member)
    can(%i[create], SchoolClass, school: { id: school.id })
    can(%i[read update destroy], SchoolClass, school: { id: school.id }, teachers: { teacher_id: user.id })
    can(%i[read create create_batch destroy], ClassStudent, school_class: { school: { id: school.id }, teachers: { teacher_id: user.id } })
    can(%i[read], :school_owner)
    can(%i[read], :school_teacher)
    can(%i[read create create_batch update], :school_student)
    can(%i[create update destroy], Lesson) do |lesson|
      school_teacher_can_manage_lesson?(user:, school:, lesson:)
    end
    can(%i[read create_copy], Lesson, school_id: school.id, visibility: %w[teachers students])
    can(%i[create], Project) do |project|
      school_teacher_can_manage_project?(user:, school:, project:)
    end
    can(%i[read update show_context], Project, school_id: school.id, lesson: { visibility: %w[teachers students] })
    can(%i[read], Project,
        remixed_from_id: Project.where(school_id: school.id, remixed_from_id: nil, lesson_id: Lesson.where(school_class_id: ClassTeacher.where(teacher_id: user.id).select(:school_class_id))).pluck(:id))
  end

  def define_school_student_abilities(user:, school:)
    can(%i[read], School, id: school.id)
    can(%i[read], SchoolClass, school: { id: school.id }, students: { student_id: user.id })
    # Ensure no access to ClassMember resources, relationships otherwise allow access in some circumstances.
    can(%i[read], Lesson, school_id: school.id, visibility: 'students', school_class: { students: { student_id: user.id } })
    can(%i[read create update], Project, school_id: school.id, user_id: user.id, lesson_id: nil, remixed_from_id: Project.where(school_id: school.id, lesson_id: Lesson.where(visibility: 'students').select(:id)).pluck(:id))
    can(%i[read show_context], Project, lesson: { school_id: school.id, visibility: 'students', school_class: { students: { student_id: user.id } } })
    can(%i[show_finished set_finished], SchoolProject, project: { user_id: user.id, lesson_id: nil }, school_id: school.id)
  end

  def define_experience_cs_admin_abilities(user)
    return unless user&.experience_cs_admin?

    can :create, Project
    can :update, Project
    can :destroy, Project
  end

  def school_teacher_can_manage_lesson?(user:, school:, lesson:)
    is_my_lesson = lesson.school_id == school.id && lesson.user_id == user.id
    is_my_class = lesson.school_class&.teacher_ids&.include?(user.id)

    is_my_class || (is_my_lesson && !lesson.school_class)
  end

  def school_teacher_can_manage_project?(user:, school:, project:)
    is_my_project = project.school_id == school.id && project.user_id == user.id
    is_my_lesson = project.lesson && project.lesson.user_id == user.id

    is_my_project && (is_my_lesson || !project.lesson)
  end
end
