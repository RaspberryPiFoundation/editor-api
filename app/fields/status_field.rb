# frozen_string_literal: true

require 'administrate/field/base'

class StatusField < Administrate::Field::Base
  def to_s
    job_status
  end

  def job_status
    return 'unknown' if data.blank?

    job = GoodJob::Execution.find_by(active_job_id: data)
    return 'not_found' unless job

    return 'failed' if job.error.present?
    return 'completed' if job.finished_at.present?
    return 'scheduled' if job.scheduled_at.present? && job.scheduled_at > Time.current
    return 'running' if job.performed_at.present? && job.finished_at.nil?

    'queued'
  end

  def status_class
    case job_status
    when 'completed' then 'status-completed'
    when 'failed' then 'status-failed'
    when 'running' then 'status-running'
    when 'queued', 'scheduled' then 'status-queued'
    else 'status-unknown'
    end
  end
end
