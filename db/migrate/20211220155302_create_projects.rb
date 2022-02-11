# frozen_string_literal: true

class CreateProjects < ActiveRecord::Migration[7.0]
  def change
    create_table :projects, id: :uuid do |t|
      t.uuid :user_id
      t.string :name
      t.string :identifier
      t.string :project_type, null: false, default: 'python'

      t.timestamps
    end

    add_index :projects, :identifier
  end
end
