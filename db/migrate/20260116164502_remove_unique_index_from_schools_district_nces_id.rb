class RemoveUniqueIndexFromSchoolsDistrictNcesId < ActiveRecord::Migration[7.2]
  def change
    remove_index :schools, name: "index_schools_on_district_nces_id"
  end
end
