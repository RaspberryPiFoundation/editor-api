class AddIndexFieldToProjectComponents < ActiveRecord::Migration[7.0]
  def change
    add_column :components, :index, :integer
  end
end
