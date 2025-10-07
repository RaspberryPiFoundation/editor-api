class ChangeUserJobsToBatchId < ActiveRecord::Migration[7.2]
  def change
    add_column :user_jobs, :good_job_batch_id, :uuid
  end
end
