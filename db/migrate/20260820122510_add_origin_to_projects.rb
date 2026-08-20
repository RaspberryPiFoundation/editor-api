# frozen_string_literal: true

class AddOriginToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :origin, :string
    add_index :projects, :origin, where: 'origin IS NOT NULL'
  end
end
