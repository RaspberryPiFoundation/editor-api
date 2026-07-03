class AddArchivedAtToSchools < ActiveRecord::Migration[8.1]
  def change
    add_column :schools, :archived_at, :datetime
  end
end
