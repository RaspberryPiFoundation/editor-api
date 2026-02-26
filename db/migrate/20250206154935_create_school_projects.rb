class CreateSchoolProjects < ActiveRecord::Migration[7.1]
  def change
    create_table :school_projects, id: :uuid do |t|
      t.references :school, foreign_key: true, type: :uuid
      t.references :project, null: false, foreign_key: true, type: :uuid
      t.boolean :finished, default: false
      t.timestamps
    end
  end
end
