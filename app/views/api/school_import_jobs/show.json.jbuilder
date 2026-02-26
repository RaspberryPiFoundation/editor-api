# frozen_string_literal: true

json.id @job.active_job_id
json.status @status
json.created_at @job.created_at
json.finished_at @job.finished_at
json.job_class @job.job_class

if @result.present?
  json.results @result.results
elsif @status == 'succeeded'
  json.message 'Job completed successfully'
end

json.error @job.error if @job.error.present?
