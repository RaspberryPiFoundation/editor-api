# frozen_string_literal: true

class AddSubmittedProjectsCountToLessons < ActiveRecord::Migration[7.2]
  def change
    add_column :lessons, :submitted_projects_count, :integer, null: false, default: 0
  end
end
