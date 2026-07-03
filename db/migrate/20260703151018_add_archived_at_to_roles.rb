class AddArchivedAtToRoles < ActiveRecord::Migration[8.1]
  def change
    add_column :roles, :archived_at, :datetime
  end
end
