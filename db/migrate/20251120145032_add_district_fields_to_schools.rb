class AddDistrictFieldsToSchools < ActiveRecord::Migration[7.2]
  def change
    add_column :schools, :district_name, :string
    add_column :schools, :district_nces_id, :string

    add_index :schools, :district_nces_id
  end
end
