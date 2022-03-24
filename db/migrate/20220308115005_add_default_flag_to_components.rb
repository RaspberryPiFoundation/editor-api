class AddDefaultFlagToComponents < ActiveRecord::Migration[7.0]
  def change
    add_column :components, :default, :boolean, null: false, default: false
  end
end
