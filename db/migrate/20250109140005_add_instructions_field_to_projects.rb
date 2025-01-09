class AddInstructionsFieldToProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :projects, :instructions, :text
  end
end
