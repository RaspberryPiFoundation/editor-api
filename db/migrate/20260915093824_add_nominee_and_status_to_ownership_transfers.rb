# frozen_string_literal: true

class AddNomineeAndStatusToOwnershipTransfers < ActiveRecord::Migration[8.1]
  def change
    add_column :ownership_transfers, :nominated_user_id, :uuid, null: false
    add_column :ownership_transfers, :requested_by_user_id, :uuid, null: false
    add_column :ownership_transfers, :status, :string, null: false, default: 'pre_pending'
  end
end
