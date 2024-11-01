class RemoveClassTeacherId < ActiveRecord::Migration[7.1]
  def up
    remove_column :school_classes, :teacher_id
  end

  def down
    add_column :school_classes, :teacher_id, :uuid, null: false
    SchoolTeacher.find_each do |school_teacher|
      school_class = school_teacher.school_classes.first
      school_class.update!(teacher_id: school_teacher.teacher_id)
    end
  end
end
