class AddFinishedToProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :projects, :finished, :boolean
  end
end
