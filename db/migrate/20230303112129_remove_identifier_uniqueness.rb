class RemoveIdentifierUniqueness < ActiveRecord::Migration[7.0]
  def up
    remove_index :projects, :identifier, unique: true
    add_index :projects, :identifier
  end

  def down
    remove_index :projects, :identifier
    add_index :projects, :identifier, unique: true
  end
end
