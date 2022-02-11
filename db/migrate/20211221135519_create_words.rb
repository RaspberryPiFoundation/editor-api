# frozen_string_literal: true

class CreateWords < ActiveRecord::Migration[7.0]
  def change
    create_table :words, id: :uuid do |t|
      t.string :word
    end
    add_index :words, :word
  end
end
