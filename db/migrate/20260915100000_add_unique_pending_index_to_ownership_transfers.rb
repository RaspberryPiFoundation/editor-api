# frozen_string_literal: true

class AddUniquePendingIndexToOwnershipTransfers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :ownership_transfers, :school_id,
              unique: true,
              where: "status = 'pending'",
              name: 'index_ownership_transfers_on_school_id_when_pending',
              algorithm: :concurrently
  end
end
