class AddIsLiveToProjects < ActiveRecord::Migration[7.0]
  def change
    add_column :projects, :is_live, :boolean
  end
end
