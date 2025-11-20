class CreateFeedback < ActiveRecord::Migration[7.2]
  def change
    create_table :feedback, id: :uuid do |t|
      t.references :school_project, foreign_key: true, type: :uuid
      t.text :content
      t.uuid :user_id, null: false
      t.timestamps
    end
  end
end
