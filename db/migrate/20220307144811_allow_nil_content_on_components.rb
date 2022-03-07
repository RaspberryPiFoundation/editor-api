class AllowNilContentOnComponents < ActiveRecord::Migration[7.0]
  def up
    change_column :components, :content, :string, null: true
  end

  def down
    change_column :components, :content, :string, null: false
  end
end
