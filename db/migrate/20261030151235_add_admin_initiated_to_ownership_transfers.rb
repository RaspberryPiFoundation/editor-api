class AddAdminInitiatedToOwnershipTransfers < ActiveRecord::Migration[8.1]
  def change
    add_column :ownership_transfers, :admin_initiated, :boolean, default: false, null: false
  end
end
