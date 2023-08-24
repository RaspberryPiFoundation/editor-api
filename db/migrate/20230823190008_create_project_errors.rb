class CreateProjectErrors < ActiveRecord::Migration[7.0]
  def change
    create_table :project_errors, id: :uuid do |t|
      t.references :project, type: :uuid, foreign_key: true
      t.string :error, null: false
      t.uuid :user_id
      t.timestamps
    end
  end
end
