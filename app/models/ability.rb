# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    can :show, Project, user_id: nil
    can :upload, Project, user_id: nil

    return if user.blank?

    can %i[create show index destroy update], Project, user_id: user
  end
end
