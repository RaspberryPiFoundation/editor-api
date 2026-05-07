class AddJoinCodeToSchoolClasses < ActiveRecord::Migration[7.2]
  def change
    add_column :school_classes, :join_code, :string
    add_index :school_classes, :join_code, unique: true
  end
end
