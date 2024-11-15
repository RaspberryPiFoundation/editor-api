# frozen_string_literal: true

module Api
  class UserJobsController < ApiController
    before_action :authorize_user

    def index
      user_jobs = UserJob.where(user_id: current_user.id).includes(:good_job)
      jobs = user_jobs.map { |user_job| job_attributes(user_job.good_job) }
      if jobs.any?
        render json: { jobs: }, status: :ok
      else
        render json: { error: 'No jobs found' }, status: :not_found
      end
    end

    def show
      user_job = UserJob.find_by(good_job_id: params[:id], user_id: current_user.id)
      job = job_attributes(user_job.good_job)
      if job
        render json: { job: }, status: :ok
      else
        render json: { error: 'Job not found' }, status: :not_found
      end
    end

    private

    def job_attributes(job)
      {
        id: job.id,
        concurrency_key: job.concurrency_key,
        status: job.status,
        scheduled_at: job.scheduled_at,
        performed_at: job.performed_at,
        finished_at: job.finished_at,
        error: job.error
      }
    end
  end
end
