class DefaultLessonVisibilityToTeachers < ActiveRecord::Migration[7.1]
  def up
    change_column_default :lessons, :visibility, 'teachers'
  end

  def down
    change_column_default :lessons, :visibility, 'private'
  end
end
