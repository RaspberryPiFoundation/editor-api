class RenameClassMembersToClassStudents < ActiveRecord::Migration[7.1]
  def up
    rename_table :class_members, :class_students
  end

  def down
    rename_table :class_students, :class_members
  end
end
