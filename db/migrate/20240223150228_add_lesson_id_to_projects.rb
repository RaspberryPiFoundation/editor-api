class AddLessonIdToProjects < ActiveRecord::Migration[7.0]
  def change
    add_reference :projects, :lesson, type: :uuid, foreign_key: true, index: true
  end
end
