# frozen_string_literal: true

require 'administrate/field/base'

class StatusField < Administrate::Field::Base
  def to_s
    job_status
  end

  def job_status
    return 'unknown' if data.blank?

    job = GoodJob::Job.find_by(active_job_id: data)
    return 'not_found' unless job

    return 'discarded' if job.discarded?
    return 'succeeded' if job.succeeded?
    return 'failed' if job.finished? && job.error.present?
    return 'running' if job.running?
    return 'scheduled' if job.scheduled_at.present? && job.scheduled_at > Time.current

    'queued'
  end

  def status_class
    case job_status
    when 'succeeded' then 'status-completed'
    when 'completed' then 'status-completed'
    when 'failed' then 'status-failed'
    when 'discarded' then 'status-failed'
    when 'running' then 'status-running'
    when 'queued', 'scheduled' then 'status-queued'
    else 'status-unknown'
    end
  end
end
