class AllowGoodJobIdToBeNull < ActiveRecord::Migration[7.2]
  def change
    change_column_null :user_jobs, :good_job_id, true
  end
end
