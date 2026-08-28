# frozen_string_literal: true

class AddSourceProjectToProjects < ActiveRecord::Migration[8.1]
  def change
    add_reference :projects, :source_project,
      type: :uuid,
      foreign_key: { to_table: :projects, on_delete: :nullify }
  end
end
