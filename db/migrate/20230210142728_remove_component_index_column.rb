class RemoveComponentIndexColumn < ActiveRecord::Migration[7.0]
  def change
    remove_column :components, :index
  end
end
