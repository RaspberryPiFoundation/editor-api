# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    can :read, Project, user_id: nil

    return if user.blank?

    can %i[create read show index destroy update], Project, user_id: user
  end
end
