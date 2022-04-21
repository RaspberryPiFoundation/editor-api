# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    can :show, Project

    return if user.blank?

    can %i[create index destroy update], Project, user_id: user
  end
end
