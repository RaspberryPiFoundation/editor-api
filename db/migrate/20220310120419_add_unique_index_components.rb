class AddUniqueIndexComponents < ActiveRecord::Migration[7.0]
  def change
    add_index :components, [:index, :project_id], unique: true
  end
end
