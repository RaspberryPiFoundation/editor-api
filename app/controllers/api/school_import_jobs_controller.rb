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
      job = GoodJob::Job.find_by(active_job_id: params[:id])

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
      if job.succeeded?
        result = SchoolImportResult.find_by(job_id: job.active_job_id)
        if result
          response[:results] = result.results
        else
          response[:message] = 'Job completed successfully'
        end
      end

      # Include error if job failed or was discarded
      if job.error.present?
        response[:error] = job.error
        response[:status] = job.discarded? ? 'discarded' : 'failed'
      end

      response
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
