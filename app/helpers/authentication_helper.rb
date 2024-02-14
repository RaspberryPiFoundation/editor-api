# frozen_string_literal: true

# TODO: re-enable cop
# rubocop:disable Rails/HelperInstanceVariable

module AuthenticationHelper
  def current_user
    return @current_user if @current_user
    return nil unless session[:current_user]

    @current_user = User.new(session[:current_user])
  end

  def current_user=(user)
    session[:current_user] = user.serializable_hash

    @current_user = user
  end
end

# rubocop:enable Rails/HelperInstanceVariable
