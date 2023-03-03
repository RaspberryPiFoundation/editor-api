class MarkUnownedProjectsAsEnglish < ActiveRecord::Migration[7.0]
  def up
    Project.find_each do |project|
      if project.user_id.nil?
        project.update_attribute(:project_locale, 'en')
      end
    end
  end

  def down
    Project.find_each do |project|
      project.update_attribute(:project_locale, nil)
    end
  end
end
