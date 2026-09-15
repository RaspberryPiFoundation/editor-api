# frozen_string_literal: true

class AddNomineeAndStatusToOwnershipTransfers < ActiveRecord::Migration[8.1]
  def change
    add_column :ownership_transfers, :nominated_user_id, :uuid, null: false
    add_column :ownership_transfers, :requested_by_user_id, :uuid, null: false
    add_column :ownership_transfers, :status, :integer, null: false, default: 0
  end
end
