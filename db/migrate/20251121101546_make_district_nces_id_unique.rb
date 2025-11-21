class MakeDistrictNcesIdUnique < ActiveRecord::Migration[7.2]
  def change
    remove_index :schools, :district_nces_id
    add_index :schools, :district_nces_id, unique: true
  end
end
