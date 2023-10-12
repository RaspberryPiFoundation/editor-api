# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    can :show, Project, user_id: nil, is_live: true
    can :show, Component, project: { user_id: nil, is_live: true }


    return if user.blank?

    can %i[show read create update destroy], Project, user_id: user
    can %i[show read create update destroy], Component, project: { user_id: user }
  end
end
