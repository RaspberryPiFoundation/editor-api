class AssociateRemixedProjectsWithTheirParentProject < ActiveRecord::Migration[7.0]
  def change
    add_reference :projects, :remixed_from, references: :projects
  end
end
