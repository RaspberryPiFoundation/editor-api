# frozen_string_literal: true

class CreateComponents < ActiveRecord::Migration[7.0]
  def change
    create_table :components, id: :uuid do |t|
      t.references :project, type: :uuid, foreign_key: true
      t.string :name, null: false
      t.string :extension, null: false
      t.text :content, null: false
      t.timestamps
    end
  end
end
