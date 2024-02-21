class CreateLessons < ActiveRecord::Migration[7.0]
  def change
    create_table :lessons, id: :uuid do |t|
      t.references :school, type: :uuid, foreign_key: true, index: true
      t.references :school_class, type: :uuid, foreign_key: true, index: true
      t.uuid :user_id, null: false

      t.string :name, null: false
      t.string :description
      t.string :visibility, null: false, default: 'private'

      t.datetime :due_date
      t.datetime :archived_at
      t.timestamps
    end

    add_index :lessons, :user_id
    add_index :lessons, :name
    add_index :lessons, :visibility
    add_index :lessons, :archived_at
  end
end
