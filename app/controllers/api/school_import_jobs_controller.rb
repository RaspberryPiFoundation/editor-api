# frozen_string_literal: true

module Api
  class SchoolImportJobsController < ApiController
    before_action :authorize_user

    def show
      authorize! :read, :school_import_job
      job = find_job

      if job.nil?
        render json: SchoolImportError.format_error(:job_not_found, 'Job not found'), status: :not_found
        return
      end

      render json: build_job_response(job), status: :ok
    end

    private

    def find_job
      # GoodJob stores jobs in the good_jobs table as Executions
      # The job_id returned to users is the ActiveJob ID
      # We need to query by active_job_id, not by execution id
      job = GoodJob::Execution.find_by(active_job_id: params[:id])

      # Verify this is an import job (security check)
      return nil unless job && job.job_class == SchoolImportJob.name

      job
    end

    def build_job_response(job)
      response = {
        id: job.active_job_id,
        status: job_status(job),
        created_at: job.created_at,
        finished_at: job.finished_at,
        job_class: job.job_class
      }

      # If job is finished successfully, get results from dedicated table
      if job.finished_at.present? && job.error.blank?
        result = SchoolImportResult.find_by(job_id: job.active_job_id)
        if result
          response[:results] = result.results
        else
          response[:message] = 'Job completed successfully'
        end
      end

      # Include error if job failed
      if job.error.present?
        response[:error] = job.error
        response[:status] = 'failed'
      end

      response
    end

    def job_status(job)
      return 'failed' if job.error.present?
      return 'completed' if job.finished_at.present?
      return 'scheduled' if job.scheduled_at.present? && job.scheduled_at > Time.current
      return 'running' if job.performed_at.present? && job.finished_at.nil?

      'queued'
    end
  end
end
