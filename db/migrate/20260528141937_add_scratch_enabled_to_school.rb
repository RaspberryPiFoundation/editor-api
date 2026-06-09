class AddScratchEnabledToSchool < ActiveRecord::Migration[8.1]
  def change
      add_column :schools, :scratch_enabled, :boolean, default: false, null: false
  end
end
