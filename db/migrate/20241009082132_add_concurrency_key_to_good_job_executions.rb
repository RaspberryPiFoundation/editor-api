class AddConcurrencyKeyToGoodJobExecutions < ActiveRecord::Migration[6.0]
  def change
    add_column :good_job_executions, :concurrency_key, :string
    add_index :good_job_executions, :concurrency_key
  end
end
