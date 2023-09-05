class NullifyProjectErrorReferenceOnDelete < ActiveRecord::Migration[7.0]
  def up
    change_column :project_errors, :project_id, :uuid, foreign_key: true, on_delete: :nullify
  end

  def down
    change_column :project_errors, :project_id, :uuid, foreign_key: true, on_delete: :restrict
  end
end
