# This migration adds the optional `object_changes` column, in which PaperTrail
# will store the `changes` diff for each update event. See the readme for
# details.
class AddMetaColumnsToVersions < ActiveRecord::Migration[7.1]
  def change
    add_column :versions, :meta_project_id, :uuid
    add_column :versions, :meta_school_id, :uuid
    add_column :versions, :meta_remixed_from_id, :uuid
  end
end
