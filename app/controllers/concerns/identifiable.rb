# frozen_string_literal: true

module Identifiable
  extend ActiveSupport::Concern

  included do
    before_action :load_current_user
    attr_reader :current_user
  end

  def load_current_user
    header = request.headers['Authorization']&.strip
    return if header.blank?

    token = extract_token(header)

    @current_user = User.from_token(token:)
    return if @current_user.blank?
    return unless RequestStore.respond_to?(:active?) && RequestStore.active?

    RequestStore.store[:safeguarding_flag_users_by_token] ||= {}
    RequestStore.store[:safeguarding_flag_users_by_token][token] = @current_user
  end

  def extract_token(header)
    header.sub(/^Bearer\s+/i, '')
  end
end
