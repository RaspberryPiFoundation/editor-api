# frozen_string_literal: true

module Admin
  class ApplicationController < Administrate::ApplicationController
    include AuthenticationHelper

    before_action :authenticate_admin

    helper_method :current_user

    def authenticate_admin
      puts current_user.inspect
      redirect_to '/', alert: 'Not authorized.' unless current_user&.admin?
    end
  end
end
