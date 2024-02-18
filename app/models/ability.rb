# frozen_string_literal: true

class Ability
  include CanCan::Ability

  # rubocop:disable Metrics/AbcSize, Layout/LineLength
  def initialize(user)
    can :show, Project, user_id: nil
    can :show, Component, project: { user_id: nil }

    return unless user

    can %i[read create update destroy], Project, user_id: user.id
    can %i[read create update destroy], Component, project: { user_id: user.id }

    can %i[create], School # The user agrees to become a school-owner by creating a school.
    can %i[create], Lesson # Public lessons can be created.

    user.organisation_ids.each do |organisation_id|
      if user.school_owner?(organisation_id:)
        can(%i[read update destroy], School, id: organisation_id)
        can(%i[read create update destroy], SchoolClass, school: { id: organisation_id })
        can(%i[read create destroy], ClassMember, school_class: { school: { id: organisation_id } })
        can(%i[read create destroy], :school_owner)
        can(%i[read create destroy], :school_teacher)
        can(%i[read create create_batch update destroy], :school_student)
      end

      if user.school_teacher?(organisation_id:)
        can(%i[read], School, id: organisation_id)
        can(%i[create], SchoolClass, school: { id: organisation_id })
        can(%i[read update destroy], SchoolClass, school: { id: organisation_id }, teacher_id: user.id)
        can(%i[read create destroy], ClassMember, school_class: { school: { id: organisation_id }, teacher_id: user.id })
        can(%i[read], :school_owner)
        can(%i[read], :school_teacher)
        can(%i[read create create_batch update], :school_student)
      end

      if user.school_student?(organisation_id:)
        can(%i[read], School, id: organisation_id)
        can(%i[read], SchoolClass, school: { id: organisation_id }, members: { student_id: user.id })
      end
    end
  end
  # rubocop:enable Metrics/AbcSize, Layout/LineLength
end
