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

Rails.application.configure do
  # The create_students_job queue is a serial queue that allows only one job at a time.
  # DO NOT change the value of create_students_job:1 without understanding the implications
  # of processing more than one user creation job at once.
  config.good_job.queues = 'create_students_job:1;import_schools_job:1;default:5'
end
