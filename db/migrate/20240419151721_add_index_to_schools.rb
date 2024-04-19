class AddIndexToSchools < ActiveRecord::Migration[6.0]
  def change
    add_index :schools, :reference, unique: true
  end
end
