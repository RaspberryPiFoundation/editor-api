class RemoveClassTeacherId < ActiveRecord::Migration[7.1]
  def up
    remove_column :school_classes, :teacher_id
  end

  def down
    add_column :school_classes, :teacher_id, :uuid
    ClassTeacher.find_each do |class_teacher|
      school_class = class_teacher.school_class
      school_class.update!(teacher_id: class_teacher.teacher_id)
    end
    change_column_null :school_classes, :teacher_id, false
  end
end
