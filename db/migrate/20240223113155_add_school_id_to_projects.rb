class AddSchoolIdToProjects < ActiveRecord::Migration[7.0]
  def change
    add_reference :projects, :school, type: :uuid, foreign_key: true, index: true
  end
end
