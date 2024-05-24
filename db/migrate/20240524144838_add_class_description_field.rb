class AddClassDescriptionField < ActiveRecord::Migration[7.0]
  def change
    add_column :school_classes, :description, :string
  end
end
