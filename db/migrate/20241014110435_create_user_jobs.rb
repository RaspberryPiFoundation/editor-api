class CreateUserJobs < ActiveRecord::Migration[7.1]
  def change
    create_table :user_jobs, id: :uuid do |t|
      t.uuid :user_id, null: false, type: :uuid
      t.uuid :good_job_id, null: false, type: :uuid

      t.timestamps
    end

    add_foreign_key :user_jobs, :good_jobs, column: :good_job_id
    add_index :user_jobs, [:user_id, :good_job_id], unique: true
  end
end
