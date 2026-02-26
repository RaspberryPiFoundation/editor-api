# frozen_string_literal: true

class AdminSessionConstraint
  def matches?(request)
    current_user = request.session[:current_user]
    return false unless current_user

    User.new(current_user).admin?
  end
end
