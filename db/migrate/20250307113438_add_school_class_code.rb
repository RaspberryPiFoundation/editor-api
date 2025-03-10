class AddSchoolClassCode < ActiveRecord::Migration[7.1]
  def change
    add_column :school_classes, :code, :string
    add_index :school_classes, [:code, :school_id], unique: true
  end
end
