# frozen_string_literal: true

module Api
  class UserJobsController < ApiController
    before_action :authorize_user

    def index
      user_jobs = UserJob.where(user_id: current_user.id)

      batches = user_jobs.filter_map do |user_job|
        batch_attributes_for(user_job)
      end

      if batches.any?
        render json: { jobs: batches }, status: :ok
      else
        render json: { error: 'No jobs found' }, status: :not_found
      end
    end

    def show
      user_job = UserJob.find_by(
        good_job_batch_id: params[:id],
        user_id: current_user.id
      )

      batch = batch_attributes_for(user_job) if user_job
      if batch.present?
        render json: { job: batch }, status: :ok
      else
        render json: { error: 'Job not found' }, status: :not_found
      end
    end

    private

    def batch_attributes_for(user_job)
      return nil unless user_job

      begin
        batch = GoodJob::Batch.find(user_job.good_job_batch_id)
        batch_attributes(batch)
      rescue GoodJob::Batch::NotFoundError
        nil
      end
    end

    def batch_attributes(batch)
      {
        id: batch.id,
        concurrency_key: batch.description,
        status: batch_status(batch),
        finished_at: batch.finished_at
      }
    end

    # Try to emulate a Job's .status field for a batch.
    def batch_status(batch)
      # If the batch is finished or discarded, report that.
      return 'discarded' if batch.discarded?
      return 'finished'  if batch.finished?

      # If the batch is in progress, try and summarise the state of the jobs
      job_summary_status(GoodJob::Job.where(batch: batch.id))
    end

    # Summarise the status of a list of jobs.
    def job_summary_status(jobs)
      if jobs.any? { |j| j.status == :running }
        'running'
      elsif jobs.any? { |j| j.status == :retried }
        'retrying'
      elsif jobs.any? { |j| j.status == :scheduled }
        'scheduled'
      else
        'queued'
      end
    end
  end
end
