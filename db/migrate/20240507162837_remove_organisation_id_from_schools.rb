class RemoveOrganisationIdFromSchools < ActiveRecord::Migration[7.0]
  def change
    remove_column :schools, :organisation_id
  end
end
