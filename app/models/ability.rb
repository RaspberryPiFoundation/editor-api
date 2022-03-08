# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    can :read, Project

    return if user.blank?

    can :update, Project, user_id: user
  end
end
