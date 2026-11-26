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
  #
  # GOOD_JOB_QUEUES lets smaller environments (e.g. staging, with a 20-connection DB)
  # run fewer threads. Keep the total thread count within the worker's DB pool
  # (WORKER_DB_POOL in the Procfile), leaving a couple spare for GoodJob itself.
  config.good_job.queues = ENV.fetch(
    'GOOD_JOB_QUEUES',
    'create_students_job:1;import_schools_job:1;salesforce_sync:10;default:5;ai_hints:5'
  )
end
