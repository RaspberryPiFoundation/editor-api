class CreateClassTeachers < ActiveRecord::Migration[7.1]
  def change
    create_table :class_teachers, id: :uuid do |t|
      t.references :school_class, type: :uuid, foreign_key: true, index: true, null: false
      t.uuid :teacher_id, null: false
      t.timestamps
    end

    add_index :class_teachers, :teacher_id
    add_index :class_teachers, %i[school_class_id teacher_id], unique: true
  end
end
