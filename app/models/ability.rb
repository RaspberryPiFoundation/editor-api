# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    can :show, Project

    return if user.blank?

    can :index, Project, user_id: user
    can :destroy, Project, user_id: user
    can :update, Project, user_id: user
  end
end
