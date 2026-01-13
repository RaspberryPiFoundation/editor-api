class AddDeletedToSchoolClasses < ActiveRecord::Migration[7.2]
  def change
    add_column :school_classes, :deleted, :boolean, default: false, null: false
    add_index :school_classes, :deleted
  end
end
