class GenerateSchoolProjects < ActiveRecord::Migration[7.1]
  def up
    Project.all.each do |project|
      if project.school.present?
        SchoolProject.create!(school: project.school, project:)
      end
    end
  end

  def down
    SchoolProject.destroy_all
  end
end
