# frozen_string_literal: true

class Ability
  include CanCan::Ability

  # rubocop:disable Metrics/AbcSize
  def initialize(user)
    can :show, Project, user_id: nil
    can :show, Component, project: { user_id: nil }

    return unless user

    can %i[read create update destroy], Project, user_id: user.id
    can %i[read create update destroy], Component, project: { user_id: user.id }

    can %i[create], School # The user agrees to become a school-owner by creating a school.

    user.organisation_ids.each do |organisation_id|
      can(%i[read], School, id: organisation_id)

      if user.school_owner?(organisation_id:)
        can(%i[update], School, id: organisation_id)
        can(%i[read create update], SchoolClass, school: { id: organisation_id })
        can(%i[read create], ClassMember, school_class: { school: { id: organisation_id } })
        can(%i[create destroy], :school_owner)
        can(%i[create destroy], :school_teacher)
        can(%i[create destroy], :school_student)
      end

      if user.school_teacher?(organisation_id:)
        can(%i[create], SchoolClass, school: { id: organisation_id })
        can(%i[read update], SchoolClass, school: { id: organisation_id }, teacher_id: user.id)
        can(%i[read create], ClassMember, school_class: { school: { id: organisation_id }, teacher_id: user.id })
        can(%i[create], :school_student)
      end

      if user.school_student?(organisation_id:)
        can(%i[read], SchoolClass, school: { id: organisation_id }, members: { student_id: user.id })
      end
    end
  end
  # rubocop:enable Metrics/AbcSize
end
