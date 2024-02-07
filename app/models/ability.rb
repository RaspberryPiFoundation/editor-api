# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    can :show, Project, user_id: nil
    can :show, Component, project: { user_id: nil }

    return unless user

    can %i[read create update destroy], Project, user_id: user.id
    can %i[read create update destroy], Component, project: { user_id: user.id }
  end
end
