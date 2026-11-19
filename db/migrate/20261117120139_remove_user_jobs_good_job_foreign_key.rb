class RemoveUserJobsGoodJobForeignKey < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :user_jobs, :good_jobs, column: :good_job_id
  end
end
