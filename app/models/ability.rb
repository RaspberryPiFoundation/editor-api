# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    can %i[read show], Project, user_id: nil
    can %i[read show], Component, project: { user_id: nil }

    return if user.blank?

    can %i[create read show index destroy update], Project, user_id: user
    can %i[create read show index destroy update], Component, project: { user_id: user }
  end
end
