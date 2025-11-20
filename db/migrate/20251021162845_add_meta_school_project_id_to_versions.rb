class AddMetaSchoolProjectIdToVersions < ActiveRecord::Migration[7.2]
  def change
    add_column :versions, :meta_school_project_id, :string
  end
end
