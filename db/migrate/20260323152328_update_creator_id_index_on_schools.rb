class UpdateCreatorIdIndexOnSchools < ActiveRecord::Migration[7.2]
  def change
    remove_index :schools, name: "index_schools_on_creator_id"

    add_index :schools,
              :creator_id,
              unique: true,
              where: "rejected_at IS NULL",
              name: "index_schools_on_creator_id_active_only"
  end
end
