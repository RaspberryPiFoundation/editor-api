class UpdateCreatorIdIndexOnSchools < ActiveRecord::Migration[7.2]
  def up
    remove_index :schools, name: "index_schools_on_creator_id"

    add_index :schools,
              :creator_id,
              unique: true,
              where: "rejected_at IS NULL",
              name: "index_schools_on_creator_id_active_only"
  end

  def down
    remove_index :schools, name: "index_schools_on_creator_id_active_only"

    add_index :schools,
              :creator_id,
              unique: true,
              name: "index_schools_on_creator_id"
  end
end