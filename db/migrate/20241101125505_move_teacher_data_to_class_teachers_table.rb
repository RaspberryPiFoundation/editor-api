class MoveTeacherDataToClassTeachersTable < ActiveRecord::Migration[7.1]
  def up
    SchoolClass.find_each do |school_class|
      ClassTeacher.create!(school_class: school_class, teacher_id: school_class.teacher_id)
    end
  end

  def down
    ClassTeacher.destroy_all
  end
end
