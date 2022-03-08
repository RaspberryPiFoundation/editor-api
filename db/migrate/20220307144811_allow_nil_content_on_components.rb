class AllowNilContentOnComponents < ActiveRecord::Migration[7.0]
  def up
    change_column :components, :content, :string, null: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
