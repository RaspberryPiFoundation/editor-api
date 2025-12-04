# frozen_string_literal: true

module Api
  class SchoolImportJobsController < ApiController
    before_action :authorize_user

    def show
      authorize! :read, :school_import_job
      @job = find_job

      if @job.nil?
        render json: SchoolImportError.format_error(:job_not_found, 'Job not found'), status: :not_found
        return
      end

      @status = job_status(@job)
      @result = SchoolImportResult.find_by(job_id: @job.active_job_id) if @job.succeeded?
      render :show, formats: [:json], status: :ok
    end

    private

    def find_job
      job = GoodJob::Job.find_by(active_job_id: params[:id])

      # Verify this is an import job (security check)
      return nil unless job && job.job_class == SchoolImportJob.name

      job
    end

    def job_status(job)
      return 'discarded' if job.discarded?
      return 'succeeded' if job.succeeded?
      return 'failed' if job_failed?(job)
      return 'running' if job.running?
      return 'scheduled' if job_scheduled?(job)

      'queued'
    end

    def job_failed?(job)
      job.finished? && job.error.present?
    end

    def job_scheduled?(job)
      job.scheduled_at.present? && job.scheduled_at > Time.current
    end
  end
end
