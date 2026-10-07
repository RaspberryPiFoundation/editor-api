# frozen_string_literal: true

class RemoveScratchEnabledFromSchools < ActiveRecord::Migration[8.1]
  def change
    remove_column :schools, :scratch_enabled, :boolean, default: false, null: false
  end
end
