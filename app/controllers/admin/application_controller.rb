# frozen_string_literal: true

module Admin
  class ApplicationController < Administrate::ApplicationController
    include AuthenticationHelper

    before_action :authenticate_admin

    helper_method :current_user

    def authenticate_admin
      redirect_to '/', alert: I18n.t('errors.admin.unauthorized') unless current_user&.admin?
    end
  end
end
