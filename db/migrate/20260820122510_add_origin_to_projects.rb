# frozen_string_literal: true

class AddOriginToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :origin, :string
  end
end
