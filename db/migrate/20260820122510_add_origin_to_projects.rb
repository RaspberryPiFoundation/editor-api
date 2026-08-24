# frozen_string_literal: true

class AddOriginToProjects < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :projects, :origin, :string, if_not_exists: true
    add_index :projects, :origin, where: 'origin IS NOT NULL',
                                  algorithm: :concurrently,
                                  if_not_exists: true
  end
end
