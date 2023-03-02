# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    can :show, Project, user_id: nil
    can :show, Component, project: { user_id: nil }

    return if user.blank?

    can %i[read create update destroy], Project, user_id: user
    can %i[read create update destroy], Component, project: { user_id: user }
  end
end
