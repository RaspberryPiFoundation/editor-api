class AddSchoolCode < ActiveRecord::Migration[7.1]
  def change
    add_column :schools, :code, :string
    add_index :schools, :code, unique: true
  end
end
