class CreateClassMembers < ActiveRecord::Migration[7.0]
  def change
    create_table :class_members, id: :uuid do |t|
      t.belongs_to :school_class, null: false
      t.uuid :student_id, null: false
      t.timestamps
    end

    add_index :class_members, :student_id
    add_index :class_members, %i[school_class_id student_id], unique: true
  end
end
