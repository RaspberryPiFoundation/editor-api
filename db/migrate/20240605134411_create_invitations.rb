class CreateInvitations < ActiveRecord::Migration[7.0]
  def change
    create_table :invitations, id: :uuid do |t|
      t.string :email_address
      t.references :school, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
