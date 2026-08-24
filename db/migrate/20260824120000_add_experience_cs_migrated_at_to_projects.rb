# frozen_string_literal: true

class AddExperienceCsMigratedAtToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :experience_cs_migrated_at, :datetime
  end
end
