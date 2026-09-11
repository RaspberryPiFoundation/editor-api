# frozen_string_literal: true

class OwnershipTransfers < ActiveRecord::Migration[8.1]
  def change
    create_table :ownership_transfers, id: :uuid do |t|
      t.string :email_address
      t.datetime :accepted_at
      t.references :school, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
