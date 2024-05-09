class AddRoles < ActiveRecord::Migration[7.0]
  def change
    create_table :roles do |t|
      t.belongs_to :user, type: :uuid
      t.belongs_to :school, type: :uuid, foreign_key: true
      t.integer :role
      t.timestamps
    end

    add_index :roles, [:user_id, :school_id, :role], unique: true
  end
end
