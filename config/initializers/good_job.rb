# frozen_string_literal: true

Rails.application.config.to_prepare do
  GoodJob::ApplicationController.class_eval do
    include AuthenticationHelper

    before_action :authenticate_admin

    helper_method :current_user

    def authenticate_admin
      redirect_to '/', alert: I18n.t('errors.admin.unauthorized') unless current_user&.admin?
    end
  end
end
