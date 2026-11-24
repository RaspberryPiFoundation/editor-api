# frozen_string_literal: true

class CreateAiHints < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_hints, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.string :status, null: false, default: 'pending'
      t.jsonb :input
      t.text :hint
      t.timestamps
    end

    add_index :ai_hints, :user_id
  end
end
