class RemoveFinishedColumnFromProjects < ActiveRecord::Migration[7.1]
  def up
    Project.all.each do |project|
      if project.school_project.present?
        project.school_project.update!(finished: project.finished)
      end
    end
    remove_column :projects, :finished
  end

  def down
    add_column :projects, :finished, :boolean, default: false
  end
end
