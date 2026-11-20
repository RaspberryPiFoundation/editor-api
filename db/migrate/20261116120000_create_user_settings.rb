# frozen_string_literal: true

class CreateUserSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :user_settings, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.jsonb :settings, null: false, default: {}
      t.timestamps
    end

    add_index :user_settings, :user_id, unique: true
  end
end
