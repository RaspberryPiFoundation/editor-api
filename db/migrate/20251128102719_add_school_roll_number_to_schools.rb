class AddSchoolRollNumberToSchools < ActiveRecord::Migration[7.2]
  def change
    add_column :schools, :school_roll_number, :string

    add_index :schools, :school_roll_number, unique: true
  end
end
