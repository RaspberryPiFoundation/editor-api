# frozen_string_literal: true

module Identifiable
  extend ActiveSupport::Concern

  included do
    before_action :load_current_user
    attr_reader :current_user
  end

  def load_current_user
    token = request.headers['Authorization']
    return if token.blank?

    @current_user = User.from_token(token:)
    return if @current_user.blank?
    return unless RequestStore.respond_to?(:active?) && RequestStore.active?

    RequestStore.store[:safeguarding_flag_users_by_token] ||= {}
    RequestStore.store[:safeguarding_flag_users_by_token][token] = @current_user
  end
end
