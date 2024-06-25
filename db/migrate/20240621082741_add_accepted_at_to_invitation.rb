class AddAcceptedAtToInvitation < ActiveRecord::Migration[7.1]
  def change
    add_column :invitations, :accepted_at, :datetime
  end
end
