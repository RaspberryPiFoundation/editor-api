# frozen_string_literal: true

class ScopeScratchAssetsToProjects < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    change_table :scratch_assets, bulk: true do |t|
      t.uuid :project_id
      t.uuid :uploaded_user_id
    end

    add_foreign_key :scratch_assets, :projects, column: :project_id

    add_index :scratch_assets, :project_id, algorithm: :concurrently

    add_index :scratch_assets,
              %i[project_id uploaded_user_id filename],
              unique: true,
              where: 'project_id IS NOT NULL',
              name: 'index_scratch_assets_on_project_uploaded_user_and_filename',
              algorithm: :concurrently

    add_index :scratch_assets,
              :filename,
              unique: true,
              where: 'project_id IS NULL',
              name: 'index_scratch_assets_on_global_filename',
              algorithm: :concurrently

    remove_index :scratch_assets, name: 'index_scratch_assets_on_filename', algorithm: :concurrently
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          'Scratch assets are scoped by project and uploader and cannot be safely collapsed back into one global row per filename'
  end
end
