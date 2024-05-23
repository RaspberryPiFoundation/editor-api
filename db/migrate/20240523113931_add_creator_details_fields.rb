class AddCreatorDetailsFields < ActiveRecord::Migration[7.0]
  def change
    add_column :schools, :creator_role, :string
    add_column :schools, :creator_department, :string
  end
end
